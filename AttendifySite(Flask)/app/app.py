from flask import Flask, request, jsonify, render_template
from flask_uploads import UploadSet, IMAGES, configure_uploads
from flask import make_response
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
import turicreate as tc
from queue import Queue
import os
import logging
from flask import send_from_directory
import threading
from marshmallow import fields
import boto3
from flask_wtf import FlaskForm
from wtforms import StringField
from werkzeug.utils import secure_filename
from flask_wtf.file import FileField
from ffmpy import FFmpeg
import json
import requests
import uuid
import time
import datetime

bucket_name = os.environ["IOSPROJECTBUCKET"]
s3 = boto3.client('s3')
latestModelTrained = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")


app = Flask(__name__)
if __name__ == "__main__":
    # Only for debugging while developing
    app.run(host='0.0.0.0', debug=True)

# configure logging
logging.basicConfig(level=logging.DEBUG,
                    format='[%(levelname)s] - %(threadName)-10s : %(message)s')

# configure video destination folder
app.config['UPLOAD_FOLDER'] = './videos'

# configure images destination folder
app.config['UPLOADED_IMAGES_DEST'] = './images'
images = UploadSet('images', IMAGES)
configure_uploads(app, images)

# configure sqlite database
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir,
                                                                    'facerecognition.sqlite')
db = SQLAlchemy(app)
ma = Marshmallow(app)

# Change from hard-code to ENV variables
# in final demo
app.config.update(dict(
    SECRET_KEY=os.environ["FLASKSECRETKEY"],
    WTF_CSRF_SECRET_KEY=os.environ["FLASKCSRFKEY"]"
))


# model/users is a many to many relationship,  that means there's a third
# table containing user id and model id
students_models = db.Table('students_models',
                           db.Column("student_id", db.String(300),
                                     db.ForeignKey('student.id')),
                           db.Column("model_id", db.Integer,
                                     db.ForeignKey('model.version'))
                           )
# model table


class Model(db.Model):
    version = db.Column(db.Integer, primary_key=True)
    url = db.Column(db.String(100))
    students = db.relationship('Student', secondary=students_models)

# Student table
#name, id, position


class Student(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    andrewid = db.Column(db.String(300))
    fullname = db.Column(db.String(300))
    classid = db.Column(db.Integer)

    def __init__(self, andrewid, fullname, classid):
        self.andrewid = andrewid
        self.fullname = fullname
        self.classid = classid

# user schema


class StudentSchema(ma.Schema):
    class Meta:
        fields = ('id', 'andrewid', 'fullname', 'classid')

# model schema


class ModelSchema(ma.Schema):
    version = fields.Int()
    url = fields.Method("add_host_to_url")
    students = ma.Nested(StudentSchema, many=True)
    # this is necessary because we need to append host to current url

    def add_host_to_url(self, obj):
        return request.host_url + obj.url


# initialize everything
student_schema = StudentSchema()
students_schema = StudentSchema(many=True)
model_schema = ModelSchema()
models_schema = ModelSchema(many=True)
db.create_all()


# error handlers
@app.errorhandler(404)
def not_found(error):
    logging.debug(request)
    return make_response(jsonify({'error': 'Not found'}), 404)


@app.errorhandler(400)
def not_found(error):
    return make_response(jsonify({'error': 'Bad request'}), 400)


class StudentForm(FlaskForm):
    andrewid = StringField()
    name = StringField()
    video = FileField()
    classid = StringField()

# index page


@app.route("/",methods=['GET'])
def index():
    return render_template('index.html')



# register user


@app.route("/students/register", methods=['GET', 'POST'])
def register_user():
    # Ensure POST request, with at least andrewid,
    if request.method == 'POST':
        if not request.form or 'andrewid' not in request.form or 'name' not in request.form or 'classid' not in request.form:
            return make_response(jsonify(
                {'status': 'failed',
                 'error': 'bad request',
                 'message:': 'Andrew ID is required'}), 400)
        else:
            andrewid = request.form['andrewid']
            fullname = request.form['name']
            classid = request.form['classid']
            logging.debug("{}: Beginning registration".format(andrewid))

            newStudent = Student(andrewid, fullname, classid)
            db.session.add(newStudent)
            db.session.commit()
            logging.debug("{}: Committed to db".format(andrewid))

            if 'video' in request.files:
                f = request.files['video']
                filename = secure_filename(f.filename)
                f.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                save_images_to_folder(os.path.join(
                    app.config['UPLOAD_FOLDER'], filename), newStudent)
                logging.debug("{}: video and photos uploaded".format(andrewid))

            if (andrewid != "negative"):
                r = requests.post('https://attendify.herokuapp.com:443/students',
                                  data={'first_name': fullname.split(' ')[0],
                                        'last_name': fullname.split(' ')[1],
                                        'andrew_id': andrewid,
                                        'active': True})
                logging.debug("{}: POST student request".format(andrewid))
                if (r.status_code == 201):
                    requests.post('https://attendify.herokuapp.com:443/enrollments',
                                  data={'course_id': classid,
                                        'andrew_id': andrewid,
                                        'active': True})
                    logging.debug("{}: POST enrollment request".format(andrewid))
            return render_template('form_registration_completion.html')
    return render_template('form_registration.html',
                           form=StudentForm(request.form))


# function that converts video into images, and
# saves images under /images/{andrewid}
def save_images_to_folder(filePath, student):
    logging.debug("{}: Begin saving images".format(student.andrewid))
    if not os.path.exists('./images/{}'.format(student.andrewid)):
        os.makedirs('./images/{}'.format(student.andrewid))
    prefix = str(uuid.uuid4())

    # Uploading the video to s3 bucket (for future use)
    s3.upload_file(filePath,
                   bucket_name, 'videos/{}/{}'.format(student.andrewid, filePath.split("/")[-1]))
    # /app/images/
    ff = FFmpeg(inputs={filePath: None},
                outputs={"./images/{}/image_{}_%d.jpg".format(student.andrewid, prefix):
                         ['-y', '-vf', 'fps=5']})
    logging.debug(ff.cmd)
    ff.run()

    # remove .DS_Store; gets autogenerated
    # frequently
    dsStore = os.path.isfile('./images/.DS_Store')
    if dsStore:
        os.remove('./images/.DS_Store')

    time.sleep(5)  # No wait function for ffmpy
    os.remove(filePath)  # Remove the video file locally, as it is not needed

    # upload first photo to S3
    logging.debug(
        "{}: Attempting to upload to s3 bucket".format(student.andrewid))
    # for filename in os.listdir('./images/{}/'.format(student.andrewid)):
    s3.upload_file('./images/{}/image_{}_1.jpg'.format(student.andrewid, prefix),
                   bucket_name, 'images/{}/image_{}_1.jpg'.format(student.andrewid, prefix))

    logging.debug("{}: POST request for photos".format(student.andrewid))
    r = requests.get(
        'https://attendify.herokuapp.com:443/photos?for_andrew_id={}'.format(student.andrewid))
    if r.text == '[]':
        r = requests.post("https://attendify.herokuapp.com:443/photos",
                          data={'andrew_id': student.andrewid,
                                'photo_url': 'https://s3.amazonaws.com/{}/images/{}/image_{}_1.jpg'.format(bucket_name, student.andrewid, prefix)})

    # get the last trained model
    model = Model.query.order_by(Model.version.desc()).first()
    if model is not None:
        # increment the version
        queue.put(model.version + 1)
    else:
        # create first version
        queue.put(1)

# endpoint to download mlModel
@app.route('/models/download')
def download():
    model = Model.query.order_by(Model.version.desc()).first()
    filename = "Faces_v{}.mlmodel".format(model.version)
    return send_from_directory('models', filename, as_attachment=True)


# endpoint to check out latest mlMode
@app.route('/models/latest')
def latest():
    global latestModelTrained
    model = Model.query.order_by(Model.version.desc()).first()
    filename = "No model has been trained yet"
    if model is not None:
        filename = "Faces_v{}.mlmodel".format(model.version)
    return render_template('lastModel.html',
                    filename = filename,
                    timestamp = latestModelTrained)

def train_model():
    global latestModelTrained
    while True:
        # get the next version
        version = queue.get()
        logging.debug('loading images')
        data = tc.image_analysis.load_images('images', with_path=True)

        # From the path-name, create a label column
        data['label'] = data['path'].apply(lambda path: path.split('/')[-2])

        # use the model version to construct a filename
        filename = 'Faces_v' + str(version)
        mlmodel_filename = filename + '.mlmodel'
        models_folder = 'models/'

        # Save the data for future use
        data.save(models_folder + filename + '.sframe')

        result_data = tc.SFrame(models_folder + filename + '.sframe')
        train_data = result_data.random_split(0.8)

        # the next line starts the training process
        model = tc.image_classifier.create(
            train_data[0], target='label', model='resnet-50', max_iterations=40,
            verbose=True, batch_size=64)

        db.session.commit()
        logging.debug('saving model')
        model.save(models_folder + filename + '.model')
        logging.debug('saving coremlmodel')
        model.export_coreml(models_folder + mlmodel_filename)
        latestModelTrained = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

        # save model data in database
        modelData = Model()
        modelData.url = models_folder + mlmodel_filename
        classes = model.classes
        for andrewid in classes:
            student = Student.query.get(andrewid)
            if student is not None:
                modelData.students.append(student)
        db.session.add(modelData)
        db.session.commit()
        logging.debug('done creating model')
        # mark this task as done
        queue.task_done()


# configure queue for training models
queue = Queue(maxsize=100)
thread = threading.Thread(target=train_model, name='TrainingDaemon')
thread.setDaemon(False)
thread.start()
