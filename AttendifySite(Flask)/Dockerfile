# Default image
FROM ubuntu:16.04

# Update and install dependencies
RUN apt-get update
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:mc3man/trusty-media
RUN apt-get install ffmpeg -y
RUN apt-get install libstdc++6 -y
RUN apt-get install liblapack3 -y
RUN apt-get install libblas3 -y
RUN apt-get install python3-pip -y
RUN pip3 install gunicorn
RUN pip3 install -U turicreate --no-cache-dir
RUN pip3 install boto3
RUN pip3 install flask-uploads
RUN pip3 install Flask-SQLAlchemy
RUN pip3 install flask-marshmallow
RUN pip3 install ffmpy
RUN pip3 install flask_wtf
RUN pip3 install wtforms
RUN pip3 install marshmallow-sqlalchemy

# Add our code
COPY ./app /app
WORKDIR ./app

# Default encoding
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Open up port 80 for https
EXPOSE 80

# Run the app
CMD gunicorn --bind 0.0.0.0:80 --timeout=260 app:app
