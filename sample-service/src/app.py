from flask import Flask
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from werkzeug.serving import run_simple
from flask_prometheus_metrics import register_metrics

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello World!"

# provide app's version and deploy environment/config name to set a gauge metric
register_metrics(app,  app_version="v0.0.2", app_config="dev")

# Plug metrics WSGI app to your main app with dispatcher
dispatcher = DispatcherMiddleware(app.wsgi_app, {"/metrics": make_wsgi_app()})

run_simple(hostname='0.0.0.0', port=5001, application=dispatcher)