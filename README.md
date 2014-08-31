sr26
====

Fancy web interface to the USDA health data.

Angular and D3 on the clientside, Django on the server.


Development Install
===================

The serverside code is written against Python 3.4.1 and Django 1.7.

Once you have Python 3 installed and a virtualenv:

    pip install -r requirements.txt

Verfiy your install with:

    python manage.py shell_plus

Change into the main static directory and install the JavaScript dependencies:

    cd sr26/static/js
    bower install

Now you should be able to go to the root directory and:

    ./manage.py runserver 9090

Point your browser to http://localhost:9090/static/index.html
