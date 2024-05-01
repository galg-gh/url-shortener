import os
from flask import Flask, request, jsonify, redirect
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from nanoid import generate

app = Flask(__name__)

# MongoDB setup
mongodb_url = os.environ.get('MONGODB_URL')
client = MongoClient(mongodb_url)
db = client.get_database('url_shortener')
urls_collection = db['urls']


# Endpoint to shorten a URL
@app.route('/shorten', methods=['POST'])
def shorten_url():
    data = request.get_json()
    original_url = data.get('originalUrl')

    # Check if the URL already exists in the database
    url = urls_collection.find_one({'originalUrl': original_url})
    if url:
        return jsonify({'shortenedUrl': f"{request.host_url}{url['shortenedId']}"})

    shortened_id = generate(size=6)
    while urls_collection.find_one({'shortenedId': shortened_id}):
        shortened_id = generate(size=6)

    if not original_url.startswith('http://') and not original_url.startswith('https://'):
        original_url = 'https://' + original_url

    try:
        urls_collection.insert_one({'originalUrl': original_url, 'shortenedId': shortened_id})
        return jsonify({'shortenedUrl': f"{request.host_url}{shortened_id}"})
    except DuplicateKeyError:
        return jsonify({'error': 'Internal Server Error'}), 500


# Endpoint to redirect shortened URL to original URL
@app.route('/<shortened_id>', methods=['GET'])
def redirect_url(shortened_id):
    url = urls_collection.find_one({'shortenedId': shortened_id})
    if url:
        return redirect(url['originalUrl'])
    else:
        return 'URL not found', 404


# Start the server
if __name__ == '__main__':
    server_url = os.environ.get('SERVER_URL', '0.0.0.0')
    server_port = os.environ.get('SERVER_PORT', 5000)
    app.run(host=server_url, port=int(server_port))
