# Copyright (c) 2017, Apple Inc. All rights reserved.
#
# Use of this source code is governed by a BSD-3-clause license that can be
# found in the LICENSE.txt file or at https://opensource.org/licenses/BSD-3-Clause

"""
Utilities to compress Neural Network Models
"""
from __future__ import print_function as _
from __future__ import division as _
from __future__ import absolute_import as _

import numpy as _np
import sys, os
from .optimization_utils import _optimize_nn

from coremltools.models import (
    _SUPPORTED_QUANTIZATION_MODES, 
    _QUANTIZATION_MODE_DEQUANTIZE, 
    _QUANTIZATION_MODE_LOOKUP_TABLE_LINEAR, 
    _QUANTIZATION_MODE_LOOKUP_TABLE_KMEANS,
    _QUANTIZATION_MODE_CUSTOM_LOOKUP_TABLE,
    _QUANTIZATION_MODE_LINEAR_QUANTIZATION,
    _LUT_BASED_QUANTIZATION
)


from ..utils import _get_nn_layers, _wp_to_fp16wp, _get_model, macos_version
from ..._deps import HAS_SKLEARN as _HAS_SKLEARN
from ... import (_MINIMUM_QUANTIZED_MODEL_SPEC_VERSION,
                 _MINIMUM_FP16_SPEC_VERSION)


def _convert_1bit_array_to_byte_array(arr):
    # Padding if necessary
    while len(arr) < 8 or len(arr) % 8:
        arr.append(0)

    arr = _np.array(arr, dtype='uint8')
    bit_arr = []
    idx = 0
    # Iterate and combine 8-bits into a uint8
    for arr_idx in range(int(len(arr) / 8)):
        bit_arr.append(((arr[idx] << 7) & (1 << 7)) |
                        ((arr[idx+1] << 6) & (1 << 6)) |
                        ((arr[idx+2] << 5) & (1 << 5)) |
                        ((arr[idx+3] << 4) & (1 << 4)) |
                        ((arr[idx+4] << 3) & (1 << 3)) |
                        ((arr[idx+5] << 2) & (1 << 2)) |
                        ((arr[idx+6] << 1) & (1 << 1)) |
                        ((arr[idx+7] << 0) & (1 << 0))
                        )
        idx += 8
    return _np.array(bit_arr, dtype='uint8').tobytes()


def _convert_array_to_nbit_quantized_bytes(arr, nbits):
    split_arr = []
    for idx in range(len(arr)):
        for i in reversed(range(nbits)):
            split_arr.append((arr[idx] >> i) & (1 << 0))

    return _convert_1bit_array_to_byte_array(split_arr)


def _decompose_bytes_to_bit_arr(arr):
    bit_arr = []
    for idx in range(len(arr)):
        for i in reversed(range(8)):
            bit_arr.append((arr[idx] >> i) & (1 << 0))
    return bit_arr


def _get_linear_lookup_table(nbits, wp):
    a = _np.amin(wp)
    b = _np.amax(wp)
    w_all_same = True if _np.abs(a - b) < 1e-5 else False
    qa = 0
    qb = (1 << nbits)
    lookup_table = []
    for q in range(qb):
        rq = (float((q - qa) / float(qb - qa)) * float(b - a)) + float(a)
        lookup_table.append(rq)

    # Now we quantize using the LUT
    lookup_table = _np.array(lookup_table)
    quantized_wp = []
    for rw in wp:
        if w_all_same:
            qw = 0
        else:
            qw = _np.abs(lookup_table - rw).argmin()
        quantized_wp.append(qw)
    quantized_wp = _np.uint8(quantized_wp)

    return lookup_table, quantized_wp


def _get_kmeans_lookup_table(nbits, w, init='k-means++', tol=1e-2, n_init=1, rand_seed=0):
    """
    Generate K-Means lookup table given a weight parameter field

    :param nbits:
        Number of bits for quantization

    :param w:
        List of weights

    Returns
    -------
        lut - Lookup table, numpy array of shape (1 << nbits, );
        wq -  Numpy array of type numpy.uint8
    """
    if _HAS_SKLEARN:
        from sklearn.cluster import KMeans
    else:
        raise Exception('sklearn package required for k-means quantization')
    units = len(w)
    lut_len = 1 << nbits
    n_clusters = units if (units < lut_len) else lut_len
    wf = _np.array(w)
    kmeans = KMeans(n_clusters=n_clusters, init=init, tol=tol,
                    n_init=n_init, random_state=rand_seed)
    kmeans = kmeans.fit(wf.reshape(-1, 1))
    wq = kmeans.labels_[:units]
    lut = _np.zeros(lut_len)
    lut[:n_clusters] = kmeans.cluster_centers_.flatten()
    return lut, wq


def _quantize_wp(wp, nbits, qm, **kwargs):

    a = _np.amin(wp)
    b = _np.amax(wp)
    w_all_same = True if _np.abs(a - b) < 1e-5 else False

    scale = bias = lut = None
    # Linear Quantization
    if qm == _QUANTIZATION_MODE_LINEAR_QUANTIZATION:
        # Quantize weights
        qa = 0
        qb = (1 << nbits) - 1
        quantized_wp = []
        for rw in wp:
            if w_all_same:
                qw = 1
            else:
                qw = (((rw - a) / (b - a)) * (qb - qa)) + qa
            quantized_wp.append(_np.rint(qw))
        quantized_wp = _np.uint8(quantized_wp)

        # Figure our scale a biases
        if w_all_same:
            bias = 0
            scale = a
        else:
            scale = (b - a) / (qb - qa)
            bias = ((-1 * qa) * (b - a) / (qb - qa)) + a

    # Lookup table
    else:
        if qm == _QUANTIZATION_MODE_LOOKUP_TABLE_KMEANS:
            lut, qw = _get_kmeans_lookup_table(nbits, wp)
            quantized_wp = _np.uint8(qw)
        else:
            if qm == _QUANTIZATION_MODE_CUSTOM_LOOKUP_TABLE:
                if 'lut_function' not in kwargs.keys():
                    raise Exception('Custom lookup table quantization mode '
                                    'selected but no lookup table function '
                                    'passed in')

                lut_function = kwargs['lut_function']
                if not callable(lut_function):
                    raise Exception('Argument for Lookup Table passed in but '
                                    'is not callable')

                try:
                    lut, qw = lut_function(nbits, wp)
                    quantized_wp = _np.uint8(qw)
                except Exception as e:
                    raise Exception('{}\nCall to Lookup Table function failed'
                                    .format(e.message))
            elif qm == _QUANTIZATION_MODE_LOOKUP_TABLE_LINEAR:
                lut, qw = _get_linear_lookup_table(nbits, wp)
                quantized_wp = _np.uint8(qw)
            else:
                raise NotImplementedError('Quantization method "{}" not '
                                          'supported'.format(qm))

    return scale, bias, lut, quantized_wp


def _quantize_wp_field(wp, nbits, qm, outChannels=1, **kwargs):

    # De-quantization
    if qm == _QUANTIZATION_MODE_DEQUANTIZE:
        return _dequantize_wp(wp, outChannels, **kwargs)

    # If the float32 field is empty do nothing and return
    if len(wp.floatValue) == 0:
        return

    # Half precision (16-bit) quantization
    if nbits == 16:
        return _wp_to_fp16wp(wp)

    if nbits > 8:
        raise Exception('Only 8-bit and lower quantization is supported')

    if qm not in _SUPPORTED_QUANTIZATION_MODES:
        raise Exception('Quantization mode {} not supported'.format(qm))

    # No channel-wise quantization for LUT based quantization
    if qm in _LUT_BASED_QUANTIZATION:
        outChannels = 1

    if len(wp.floatValue) % outChannels:
        raise Exception('Number of channels does not divide evenly into '
                        'weights')

    # If we're doing quantization along the input axis then re-order
    # weights and then do channelwise quantization
    quantization_axis_input = False
    if 'quantization_axis' and 'shape' in kwargs.keys():
        qaxis = kwargs['quantization_axis']
        if qaxis == 'output':
            pass
        elif qaxis == 'input':
            if len(kwargs['shape']) != 4:
                raise Exception('Invalid shape {} for weight parameters. '
                                'Shape must be in the form '
                                '[Cout, Cin, Kh, Kw]')

            weights = _np.array(wp.floatValue)
            weights = weights.reshape(kwargs['shape'])
            weights = _np.transpose(weights, (1, 0, 2, 3))
            del wp.floatValue[:]
            wp.floatValue.extend(weights.flatten())
            quantization_axis_input = True
        else:
            raise Exception('Invalid quantization axis {} passed in. Allowed'
                            'values are output and input'.format(qaxis))

    qparams = wp.quantization
    qparams.numberOfBits = nbits
    uint8_weight_arr = _np.array([], dtype=_np.uint8)

    stride = len(wp.floatValue) / outChannels
    for c in range(0, outChannels):
        w = wp.floatValue[int(c*stride):int((c*stride + stride))]
        scale, bias, lut, uint8_weights = _quantize_wp(w, nbits, qm, **kwargs)
        uint8_weight_arr = _np.append(uint8_weight_arr, uint8_weights)

        if qm == _QUANTIZATION_MODE_LINEAR_QUANTIZATION:
            if c == 0:
                qparams.linearQuantization.scale
                qparams.linearQuantization.bias
            qparams.linearQuantization.scale.append(scale)
            qparams.linearQuantization.bias.append(bias)
        else:
            if c == 0:
                qparams.lookupTableQuantization.floatValue
            qparams.lookupTableQuantization.floatValue.extend(lut)

    # Set raw bytes for all weights
    wp.rawValue = bytes()
    if nbits == 8:
        wp.rawValue += uint8_weight_arr.tobytes()
    else:
        wp.rawValue += _convert_array_to_nbit_quantized_bytes(uint8_weight_arr, nbits)

    # Delete old weights
    del wp.floatValue[:]

    # Re-order raw bytes if we're quantizing along the input axis
    if quantization_axis_input:
        byteArr = _np.frombuffer(wp.rawValue, dtype=_np.uint8)
        if nbits != 8:
            bitArr = _decompose_bytes_to_bit_arr(byteArr.flatten().tolist())
            bitArr = _np.array(bitArr[:kwargs['num_weights']*nbits]) # remove padding
            bitArr = bitArr.reshape(nbits, kwargs['shape'][1], kwargs['shape'][0], kwargs['shape'][2], kwargs['shape'][3])
            bitArr = _np.transpose(bitArr, (0, 2, 1, 3, 4))
            wp.rawValue = _convert_1bit_array_to_byte_array(bitArr.flatten().tolist())
        else:     
            byteArr = byteArr.reshape(kwargs['shape'][1], kwargs['shape'][0], kwargs['shape'][2], kwargs['shape'][3])
            byteArr =  _np.transpose(byteArr, (1, 0, 2, 3))
            wp.rawValue = ''
            wp.rawValue = byteArr.tobytes()


def _dequantize_wp(wp, outChannels, **kwargs):
    if len(wp.floatValue) != 0:
        raise Exception('Params have unexpected float values')

    linear_quantization = True
    if wp.quantization.WhichOneof('QuantizationType') != 'linearQuantization':
        linear_quantization = False
        outChannels = 1

    if linear_quantization:
        if len(wp.quantization.linearQuantization.scale) != \
                len(wp.quantization.linearQuantization.bias):
            raise Exception('Linear quantization scale and bias vectors are '
                            'different lengths')

        if len(wp.quantization.linearQuantization.scale) != outChannels:
            raise Exception('Number of channels not equal to length of scale '
                            'vector')

    # If we're doing quantization along the input axis then re-order
    # raw bytes and do channelwise de-quantization
    nbits = wp.quantization.numberOfBits
    quantization_axis_input = False
    if 'quantization_axis' and 'shape' in kwargs.keys():
        qaxis = kwargs['quantization_axis']
        if qaxis == 'output':
            pass
        elif qaxis == 'input':
            if len(kwargs['shape']) != 4:
                raise Exception('Invalid shape {} for weight parameters. '
                                'Shape must be in the form '
                                '[Cout, Cin, Kh, Kw]')

            byteArr = _np.frombuffer(wp.rawValue, dtype=_np.uint8)
            if nbits != 8:
                bitArr = _decompose_bytes_to_bit_arr(byteArr.flatten().tolist())
                bitArr = _np.array(bitArr[:kwargs['num_weights']*nbits]) # remove padding
                bitArr = bitArr.reshape(nbits, kwargs['shape'][0], kwargs['shape'][1], kwargs['shape'][2], kwargs['shape'][3])
                bitArr = _np.transpose(bitArr, (0, 2, 1, 3, 4))
                wp.rawValue = _convert_1bit_array_to_byte_array(bitArr.flatten().tolist())
            else:
                byteArr = byteArr.reshape(kwargs['shape'])
                byteArr = _np.transpose(byteArr, (1, 0, 2, 3))
                wp.rawValue = byteArr.tobytes()
            quantization_axis_input = True
        else:
            raise Exception('Invalid de-quantization axis {} passed in. '
                            'Allowed values are output and input'.format(qaxis))

    uint8_weights = _np.fromstring(wp.rawValue, dtype=_np.uint8)
    bit_arr = []
    for idx in range(len(uint8_weights)):
        for b in reversed(range(0, 8)):
            bit = 0 if not (uint8_weights[idx] & (1 << b)) else 1
            bit_arr.append(bit)

    num_weights = len(bit_arr) / nbits
    if 'num_weights' in kwargs.keys():
        num_weights = kwargs['num_weights']

    dw = []
    idx = 0
    for i in range(0, num_weights):
        w = 0
        for b in reversed(range(0, nbits)):
            w += bit_arr[idx] << b
            idx += 1
        dw.append(w)

    if linear_quantization and len(dw) % len(wp.quantization.linearQuantization.scale) != 0:
        raise Exception('Number of channels does not divide evenly into '
                        'weights')

    stride = int(len(dw) / outChannels)
    w_idx = 0
    for c in range(0, outChannels):
        if linear_quantization:
            scale = wp.quantization.linearQuantization.scale[c]
            bias = wp.quantization.linearQuantization.bias[c]
            for m in range(0, stride):
                dw[w_idx] = (float(dw[w_idx]) * scale) + bias
                w_idx += 1
        else:
            lut = _np.array(wp.quantization.lookupTableQuantization.floatValue)
            for m in range(0, stride):
                dw[w_idx] = lut[dw[w_idx]]
                w_idx += 1

    wp.rawValue = bytes()
    wp.quantization.Clear()

    if quantization_axis_input:
        dw = _np.array(dw).reshape(kwargs['shape'][1], kwargs['shape'][0], kwargs['shape'][2], kwargs['shape'][3])
        dw = _np.transpose(dw, (1, 0, 2, 3))
        dw = dw.flatten()

    wp.floatValue.extend(dw)


def _dequantize_spec(spec):
    return _quantize_nn_spec(spec, 1, _QUANTIZATION_MODE_DEQUANTIZE)


def _quantize_nn_spec(spec, nbits, qm, **kwargs):
    ignored_layers = [
        'pooling', 'mvn', 'l2normalize', 'softmax',
        'lrn', 'crop', 'padding', 'upsample', 'unary', 'add',
        'multiply', 'average', 'max', 'min', 'dot', 'reduce',
        'reshape', 'flatten', 'permute', 'concat', 'split',
        'sequenceRepeat', 'reorganizeData', 'slice', 'custom'
    ]

    quantized_layers = [
        'convolution', 'innerProduct', 'embedding',
        'batchnorm', 'scale', 'bias', 'loadConstant',
        'simpleRecurrent', 'gru', 'uniDirectionalLSTM',
        'biDirectionalLSTM'
    ]

    # Bump up to appropriate spec version if required
    if nbits > 8 and nbits != 16:
        raise Exception('Only half precision (16-bit), 8-bit and lower '
                        'quantization is supported')

    if nbits == 16:
        spec.specificationVersion = max(_MINIMUM_FP16_SPEC_VERSION,
                                        spec.specificationVersion)
    else:
        spec.specificationVersion = max(_MINIMUM_QUANTIZED_MODEL_SPEC_VERSION,
                                        spec.specificationVersion)
        if qm not in _SUPPORTED_QUANTIZATION_MODES:
            raise Exception('Quantization mode {} not supported'.format(qm))

    layers = _get_nn_layers(spec)

    # Perform optimization step
    if nbits < 16 and qm != _QUANTIZATION_MODE_DEQUANTIZE:
        print('Optimizing Neural Network before Quantization:')
        _optimize_nn(layers)
        print('Finished optimizing network. Quantizing neural network..')

    for layer in layers:
        layer_type = layer.WhichOneof('layer')

        if layer_type in ignored_layers:
            continue

        print('Quantizing layer {}'.format(layer.name))

        if layer_type == 'convolution':
            outputChannels = layer.convolution.outputChannels
            kernelChannels = layer.convolution.kernelChannels
            kernelHeight = _np.array(layer.convolution.kernelSize)[0]
            kernelWidth = _np.array(layer.convolution.kernelSize)[1]
            nw = outputChannels*kernelChannels*kernelWidth*kernelHeight

            if layer.convolution.isDeconvolution:
                shape = _np.array([kernelChannels, outputChannels, kernelHeight, kernelWidth])
                _quantize_wp_field(layer.convolution.weights, nbits, qm, outputChannels, shape=shape, quantization_axis='input', num_weights=nw, **kwargs)
            else:
                _quantize_wp_field(layer.convolution.weights, nbits, qm, outputChannels, num_weights=nw, **kwargs)

            if layer.convolution.hasBias:
                _quantize_wp_field(layer.convolution.bias, nbits, qm, num_weights=outputChannels, **kwargs)

        # Batchnorm
        elif layer_type == 'batchnorm':
            nw = layer.batchnorm.channels
            _quantize_wp_field(layer.batchnorm.gamma, nbits, qm, num_weights=nw, **kwargs)
            _quantize_wp_field(layer.batchnorm.beta, nbits, qm, num_weights=nw, **kwargs)
            _quantize_wp_field(layer.batchnorm.mean, nbits, qm, num_weights=nw, **kwargs)
            _quantize_wp_field(layer.batchnorm.variance, nbits, qm, num_weights=nw, **kwargs)

        # InnerProduct
        elif layer_type == 'innerProduct':
            outputChannels = layer.innerProduct.outputChannels
            inputChannels = layer.innerProduct.inputChannels
            nw = outputChannels * inputChannels
            _quantize_wp_field(layer.innerProduct.weights, nbits, qm, outputChannels, num_weights=nw, **kwargs)
            if layer.innerProduct.hasBias:
                _quantize_wp_field(layer.innerProduct.bias, nbits, qm, num_weights=outputChannels, **kwargs)

        # Embedding layer
        elif layer_type == 'embedding':
            nw = layer.embedding.outputChannels * layer.embedding.inputDim
            _quantize_wp_field(layer.embedding.weights, nbits, qm, num_weights=nw, **kwargs)
            if layer.embedding.hasBias:
                nw = layer.embedding.outputChannels
                _quantize_wp_field(layer.embedding.bias, nbits, qm,  num_weights=nw, **kwargs)

        # Scale layer
        elif layer_type == 'scale':
            shape = _np.array(layer.scale.shapeScale)
            nw = _np.prod(shape)
            _quantize_wp_field(layer.scale.scale, nbits, qm, num_weights=nw, **kwargs)
            if layer.scale.hasBias:
                shape = _np.array(layer.scale.shapeBias)
                nw = _np.prod(shape)
                _quantize_wp_field(layer.scale.bias, nbits, qm, num_weights=nw, **kwargs)

        # Bias layer
        elif layer_type == 'bias':
            shape =  _np.array(layer.bias.shape)
            nw = _np.prod(shape)
            _quantize_wp_field(layer.bias.bias, nbits, qm, num_weights=nw, **kwargs)

        # LoadConstant layer
        elif layer_type == 'loadConstant':
            shape = _np.array(layer.loadConstant.shape)
            nw = _np.prod(shape)
            _quantize_wp_field(layer.loadConstant.data, nbits, qm, num_weights=nw, **kwargs)

        # Activation layer
        elif layer_type == 'activation':
            # Skip quantizing activation layers as this can introduce errors during
            # de-quantization as no information is present about the number of 
            # weights
            if nbits <=8: 
                continue
            activation_type = layer.activation.WhichOneof(
                'NonlinearityType')
            if activation_type == 'PReLU':
                _quantize_wp_field(layer.activation.PReLU.alpha, nbits, qm, **kwargs)
            elif activation_type == 'parametricSoftplus':
                _quantize_wp_field(layer.activation.parametricSoftplus.alpha, nbits, qm, **kwargs)
                _quantize_wp_field(layer.activation.parametricSoftplus.beta, nbits, qm, **kwargs)

        # Simple Recurrent
        elif layer_type == 'simpleRecurrent':
            i_size = layer.simpleRecurrent.inputVectorSize
            o_size = layer.simpleRecurrent.outputVectorSize
            nw_w = i_size * o_size
            nw_r = o_size * o_size
            _quantize_wp_field(layer.simpleRecurrent.weightMatrix, nbits, qm, num_weights=nw_w, **kwargs)
            _quantize_wp_field(layer.simpleRecurrent.recursionMatrix, nbits, qm, num_weights=nw_r, **kwargs)
            if layer.simpleRecurrent.hasBiasVector:
                _quantize_wp_field(layer.simpleRecurrent.biasVector,nbits, qm, num_weights=o_size, **kwargs)

        # GRU
        elif layer_type == 'gru':
            i_size = layer.gru.inputVectorSize
            o_size = layer.gru.outputVectorSize
            # Weight Matrix
            nw_gm = i_size * o_size
            _quantize_wp_field(layer.gru.updateGateWeightMatrix, nbits, qm, num_weights=nw_gm, **kwargs)
            _quantize_wp_field(layer.gru.resetGateWeightMatrix, nbits, qm, num_weights=nw_gm, **kwargs)
            _quantize_wp_field(layer.gru.outputGateWeightMatrix, nbits, qm, num_weights=nw_gm, **kwargs)

            # Recursion Weights
            nw_rm = o_size * o_size
            _quantize_wp_field(layer.gru.updateGateRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)
            _quantize_wp_field(layer.gru.resetGateRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)
            _quantize_wp_field(layer.gru.outputGateRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)

            if layer.gru.hasBiasVectors:
                _quantize_wp_field(layer.gru.updateGateBiasVector, nbits, qm, num_weights=o_size, **kwargs)
                _quantize_wp_field(layer.gru.resetGateBiasVector, nbits, qm, num_weights=o_size, **kwargs)
                _quantize_wp_field(layer.gru.outputGateBiasVector, nbits, qm, num_weights=o_size, **kwargs)

        # LSTM Layers
        elif layer_type in ['uniDirectionalLSTM', 'biDirectionalLSTM']:

            def _lstmwp_to_fp16_lstmwp(lstm_wp, nbits, qm, i_size, o_size, has_peephole=True, **kwargs):
                assert lstm_wp
                nw_gm = i_size * o_size
                _quantize_wp_field(lstm_wp.inputGateWeightMatrix, nbits, qm, num_weights=nw_gm, **kwargs)
                _quantize_wp_field(lstm_wp.forgetGateWeightMatrix, nbits, qm,  num_weights=nw_gm, **kwargs)
                _quantize_wp_field(lstm_wp.blockInputWeightMatrix, nbits, qm,  num_weights=nw_gm, **kwargs)
                _quantize_wp_field(lstm_wp.outputGateWeightMatrix, nbits, qm,  num_weights=nw_gm, **kwargs)

                nw_rm = o_size * o_size
                _quantize_wp_field(lstm_wp.inputGateRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)
                _quantize_wp_field(lstm_wp.forgetGateRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)
                _quantize_wp_field(lstm_wp.blockInputRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)
                _quantize_wp_field(lstm_wp.outputGateRecursionMatrix, nbits, qm, num_weights=nw_rm, **kwargs)

                _quantize_wp_field(lstm_wp.inputGateBiasVector, nbits, qm, num_weights=o_size, **kwargs)
                _quantize_wp_field(lstm_wp.forgetGateBiasVector, nbits, qm, num_weights=o_size, **kwargs)
                _quantize_wp_field(lstm_wp.blockInputBiasVector, nbits, qm, num_weights=o_size, **kwargs)
                _quantize_wp_field(lstm_wp.outputGateBiasVector, nbits, qm, num_weights=o_size, **kwargs)

                if has_peephole:
                    _quantize_wp_field(lstm_wp.inputGatePeepholeVector, nbits, qm, num_weights=o_size, **kwargs)
                    _quantize_wp_field(lstm_wp.forgetGatePeepholeVector, nbits, qm, num_weights=o_size, **kwargs)
                    _quantize_wp_field(lstm_wp.outputGatePeepholeVector, nbits, qm, num_weights=o_size, **kwargs)

            if layer_type == 'uniDirectionalLSTM':
                _lstmwp_to_fp16_lstmwp(
                    lstm_wp=layer.uniDirectionalLSTM.weightParams,
                    nbits=nbits,
                    qm=qm,
                    i_size=layer.uniDirectionalLSTM.inputVectorSize,
                    o_size=layer.uniDirectionalLSTM.outputVectorSize,
                    has_peephole=layer.uniDirectionalLSTM.params.hasPeepholeVectors,
                    kwargs=kwargs
                )
            elif layer_type == 'biDirectionalLSTM':
                for lstm_wp in layer.biDirectionalLSTM.weightParams:
                    _lstmwp_to_fp16_lstmwp(
                        lstm_wp=lstm_wp,
                        nbits=nbits,
                        qm=qm,
                        i_size=layer.biDirectionalLSTM.inputVectorSize,
                        o_size=layer.biDirectionalLSTM.outputVectorSize,
                        has_peephole=layer.biDirectionalLSTM.params.hasPeepholeVectors,
                        kwargs=kwargs
                    )

        elif layer_type == 'custom':
            print(
                'Skipping custom layer {}. Weights for this layer need to'
                'be converted manually'.format(layer.name))
            continue

        elif layer_type in quantized_layers:
            raise Exception('Quantization for ' + layer_type +
                            ' not yet implemented\n')
        else:
            raise Exception('Unknown layer ' + layer_type)

    return spec


def quantize_spec_weights(spec, nbits, quantization_mode, **kwargs):

    nn_model_types = ['neuralNetwork', 'neuralNetworkClassifier',
                      'neuralNetworkRegressor']

    # Neural network models
    if spec.WhichOneof('Type') in nn_model_types:
        return _quantize_nn_spec(spec, nbits, quantization_mode, **kwargs)

    # Recursively convert all pipeline models
    elif spec.WhichOneof('Type') == 'pipeline':
        for model_spec in spec.pipeline.models:
            quantize_spec_weights(model_spec, nbits, quantization_mode, **kwargs)

    elif spec.WhichOneof('Type') in ['pipelineClassifier',
                                        'pipelineRegressor']:
        quantize_spec_weights(spec.pipeline, nbits, quantization_mode, **kwargs)

    return spec


def _load_and_resize_image(image_path, size):
    from PIL import Image
    img = Image.open(image_path)
    return img.resize(size, Image.ANTIALIAS)


class TopKMetrics():
    def __init__(self, topk):
        self._topk = topk
        self._correct_count = 0
        self._total_count = 0

    def add_metric(self, output1, output2):
        self._total_count += 1
        if self._topk == 1:
            if output1 == output2:
                self._correct_count += 1
        else:
            self._topk = min(len(output1.keys()), self._topk)
            out1_topk =  sorted(output1, key=output1.get,reverse=True)[:self._topk]
            out2_topk =  sorted(output2, key=output2.get,reverse=True)[:self._topk]
            if out1_topk[0] in out2_topk:
                self._correct_count += 1

    def display_metrics(self):
        pcorrect = (float(self._correct_count) / float(self._total_count))* 100
        pcorrect = _np.round(pcorrect, decimals=2)
        if self._topk == 1:
            print('Top 1 Agreement: {}%\n'.format(pcorrect))
        else:
            print('Top {} Agreement: {}%\n'.format(self._topk, pcorrect))


class NoiseMetrics():
    def __init__(self):
        self._snr = []
        self._psnr = []

    @staticmethod
    def _compute_snr(arr1, arr2):
        noise = arr1 - arr2
        noise_var = _np.sum(noise ** 2) / len(noise) + 1e-7
        signal_energy = _np.sum(arr2 ** 2) / len(arr2)
        max_signal_energy = _np.amax(arr2 ** 2)
        snr = 10 * _np.log10(signal_energy / noise_var)
        psnr = 10 * _np.log10(max_signal_energy / noise_var)
        return snr, psnr

    def add_metric(self, output1, output2):
        import PIL

        # Output is Image
        if isinstance(output1, PIL.Image.Image):
            if output1.mode == 'RGBA':
                output1 = output1.convert('RGB')
                output2 = output2.convert('RGB')
            arr1 = _np.array(output1).flatten()
            arr2 = _np.array(output2).flatten()
            snr, psnr = self._compute_snr(arr1, arr2)
            self._snr.append(snr)
            self._psnr.append(psnr)

        # Output is multiArray
        else:
            arr1 = output1.flatten()
            arr2 = output2.flatten()
            snr, psnr = self._compute_snr(arr1, arr2)
            self._snr.append(snr)
            self._psnr.append(psnr)

    def display_metrics(self):
        print('SNR:  {} +/- {}'.format(_np.mean(self._snr), _np.var(self._snr)))
        print('PSNR: {} +/- {}\n'.format(_np.mean(self._psnr), _np.var(self._psnr)))


class OutputMetric():
    """
    Utility class to calculate and hold metrics between
    two model outputs
    """
    def __init__(self, name, type):
        self.name = name
        self._metrics = []

        if type == 'stringType':
            self._metrics.append(TopKMetrics(topk=1))

        elif type == 'dictionaryType':
            self._metrics.append(TopKMetrics(topk=5))

        elif type == 'imageType' or type == 'multiArrayType':
            self._metrics.append(NoiseMetrics())

        else:
            raise Exception("""Unable to determine which metric to
            compute for output: {}""".format(name))

    def add_metric(self, output1, output2):
        for metric in self._metrics:
            metric.add_metric(output1, output2)

    def display_metrics(self):
        for metric in self._metrics:
            metric.display_metrics()


class ModelMetrics():
    """
    A utility class to hold evaluation metrics
    """
    def __init__(self, spec):
        self.model_metrics = {}
        for output in spec.description.output:
            output_type = output.type.WhichOneof('Type')
            self.model_metrics[output.name] = OutputMetric(output.name, output_type)

    def add_metrics(self, model1_output, model2_output):
        outputs = model1_output.keys()
        for output in outputs:
            self.model_metrics[output].add_metric(model1_output[output], model2_output[output])

    def display_metrics(self):
        for metric in self.model_metrics:
            print('Output {}:'.format(metric))
            dash = '----------'
            for x in range(0, len(metric)):
                dash += '-'
            print(dash)
            self.model_metrics[metric].display_metrics()


def _characterize_qmodel_perf_with_data_dir(fpmodel, qspec, data_dir):
    supported_image_exts = ['jpg', 'bmp', 'png', 'jpeg']
    test_image_paths = ['{}/{}'.format(data_dir, fn) for fn in
                        os.listdir(data_dir) if
                        any(fn.endswith(ext) for ext in supported_image_exts)]

    if not test_image_paths:
        raise Exception("""Path contains no supported image files.
        Supported file types include jpg, bmp, png and jpeg.
        """.format(data_dir))

    qmodel = _get_model(qspec)
    model_metrics = ModelMetrics(qspec)

    input_name = qspec.description.input[0].name
    input_size = (qspec.description.input[0].type.imageType.width,
                  qspec.description.input[0].type.imageType.height)

    print('\n\n')
    print('Analyzing {} images'.format(len(test_image_paths)))
    print('Running Analysis this may take a while ...')
    print('\n')

    analyzed = 0
    tried = 0
    for image in test_image_paths:
        try:
            input = {input_name: _load_and_resize_image(image, input_size)}
            fp_pred = fpmodel.predict(input, useCPUOnly=True)
            q_pred = qmodel.predict(input, useCPUOnly=True)
            analyzed += 1
            model_metrics.add_metrics(fp_pred, q_pred)

        except Exception as e:
            print(e)
            continue

        # Update Progress
        tried += 1
        if tried % 10 == 0:
            sys.stdout.write('\r')
            sys.stdout.write(
                'Analyzed {}/{}'.format(tried, len(test_image_paths)))
            sys.stdout.flush()

    print('\n')
    model_metrics.display_metrics()


def _characterize_quantized_model_perf(fpmodel, qspec, sample_data):
    qmodel = _get_model(qspec)
    model_metrics = ModelMetrics(qspec)

    print('\n\n')
    print('Analyzing {} samples'.format(len(sample_data)))
    print('Running Analysis this may take a while ...')
    print('\n')

    analyzed = 0
    tried = 0
    for data in sample_data:
        try:
            fp_pred = fpmodel.predict(data, useCPUOnly=True)
            q_pred = qmodel.predict(data, useCPUOnly=True)
            analyzed += 1
            model_metrics.add_metrics(fp_pred, q_pred)

        except Exception as e:
            print(e)
            continue

        # Update Progress
        tried += 1
        if tried % 10 == 0:
            sys.stdout.write('\r')
            sys.stdout.write(
                'Analyzed {}/{}'.format(tried, len(sample_data)))
            sys.stdout.flush()

    print('\n')
    model_metrics.display_metrics()


def compare_models(full_precision_model, quantized_model,
                              sample_data):
    """
    Utility function to compare the performance of a full precision vs
    quantized model

    :param full_precision_model: MLModel
        The full precision model with float32 weights

    :param quantized_model: MLModel
        Quantized version of the model with quantized weights

    :param sample_data: str | [dict]
        Data used to characterize performance of the quantized model in
        comparison to the full precision model. Either a list of sample input
        dictionaries or an absolute path to a directory containing images.
        Path to a directory containing images is only valid for models with
        one image input. For all other models a list of sample inputs must be
        provided.

    :return:
        None. Performance metrics are printed out
    """
    emessage = ("""
    Invalid sample data provided. Only a list of dictionaries
    containing sample data or path to a folder containing images is
    supported""")

    spec = full_precision_model.get_spec()
    num_inputs = len(spec.description.input)
    if isinstance(sample_data, str):
        input_type = spec.description.input[0].type.WhichOneof('Type')
        if num_inputs != 1 or input_type != 'imageType':
            raise Exception("""Unable to analyze quantized models. Sample data
            was a path to a directory which is only supported with models with
            one image type input. Please try passing in a list of sample inputs
            as sample data.
            """)
        _characterize_qmodel_perf_with_data_dir(full_precision_model, quantized_model.get_spec(), sample_data)

    elif isinstance(sample_data, list):
        if not all(type(d) is dict for d in sample_data):
            raise Exception(emessage)
        _characterize_quantized_model_perf(full_precision_model, quantized_model.get_spec(), sample_data)

    else:
        raise Exception(emessage)


def quantize_weights(full_precision_model,
                     nbits,
                     quantization_mode="linear",
                     sample_data=None,
                     **kwargs):
    """
    Utility function to convert a full precision (float) MLModel to a
    nbit quantized MLModel (float16).

    :param full_precision_model: MLModel
        Model which will be converted to half precision. Currently conversion
        for only neural network models is supported. If a pipeline model is
        passed in then all embedded neural network models embedded within
        will be converted.

    :param nbits: Int
        Number of bits per quantized weight. Only 8-bit and lower
        quantization is supported

    :param quantization_mode: str
        One of:
         "linear":
            Simple linear quantization with scale and bias

         "linear_lut":
            Simple linear quantization represented as a lookup table

         "kmeans_lut":
            LUT based quantization, where LUT is generated by K-Means clustering

         "custom_lut":
            LUT quantization where LUT and quantized weight params are
            calculated using a custom function. If this mode is selected then
            a custom function must be passed in kwargs with key lut_function.
            The function must have input params (nbits, wp) where nbits is the
            number of quantization bits and wp is the list of weights for a
            given layer. The function should return two parameters (lut, qw)
            where lut is an array of length (2^nbits)containing LUT values and
            qw is the list of quantized weight parameters. See
            _get_linear_lookup_table for a sample implementation.

    :param sample_data: str | [dict]
        Data used to characterize performance of the quantized model in
        comparison to the full precision model. Either a list of sample input
        dictionaries or an absolute path to a directory containing images.
        Path to a directory containing images is only valid for models with
        one image input. For all other models a list of sample inputs must be
        provided.

    :param **kwargs:
        See below

    :Keyword Arguments:
        * *lut_function* (``callable function``) --
          A callable function provided when quantization mode is set to
          _QUANTIZATION_MODE_CUSTOM_LOOKUP_TABLE. See quantization_mode for
          more details

    Returns
    -------
    model: MLModel
        The quantized MLModel instance if running on macOS 10.14 or later,
        otherwise the quantized model specification is returned

    Examples
    --------
    .. sourcecode:: python
        >>> import coremltools
        >>> from coremltools.models.neural_network import quantization_utils
        >>> model = coremltools.models.MLModel('my_model.mlmodel')
        >>> quantized_model = quantization_utils.quantize_weights(model, 8, "linear")

    """
    qmode_mapping = {
        "linear": _QUANTIZATION_MODE_LINEAR_QUANTIZATION,
        "kmeans": _QUANTIZATION_MODE_LOOKUP_TABLE_KMEANS,
        "linear_lut": _QUANTIZATION_MODE_LOOKUP_TABLE_LINEAR,
        "custom_lut": _QUANTIZATION_MODE_CUSTOM_LOOKUP_TABLE,
        "dequantization": _QUANTIZATION_MODE_DEQUANTIZE
    }
    try:
        qmode = qmode_mapping[quantization_mode]
    except KeyError:
        raise Exception("Invalid quantization mode. Quantization mode must be "
                        "one of {}".format(qmode_mapping))

    print("Quantizing using {} quantization".format(quantization_mode))
    spec = full_precision_model.get_spec()
    qspec = quantize_spec_weights(spec,
                                                 nbits,
                                                 qmode,
                                                 **kwargs)

    if macos_version() < (10, 14):
        print("WARNING! Unable to return a quantized MLModel instance since OS != macOS 10.14 or later")
        print("Returning quantized model specification instead")
        return qspec

    quantized_model = _get_model(qspec)
    if not sample_data:
        return quantized_model

    compare_models(full_precision_model, quantized_model, sample_data)
    return quantized_model
