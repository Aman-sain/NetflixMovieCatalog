import sys
import os
import pytest
from flask import json

# Add the directory containing app.py to the Python path
sys.path.insert(0, '/home/runner/work/NetflixMovieCatalog/NetflixMovieCatalog')
import app

# Add the directory containing app.py to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

@pytest.fixture
def client():
    # Create a test client using the Flask application
    app.app.config['TESTING'] = True
    with app.app.test_client() as client:
        yield client

def test_home(client):
    """Test the home route."""
    rv = client.get('/')
    assert rv.status_code == 200
    assert b"This app is an API" in rv.data
    print("Test home passed.")

def test_discover_movies(client):
    """Test the /discover route for movies."""
    rv = client.get('/discover?type=movie')
    assert rv.status_code == 200
    data = json.loads(rv.data)
    assert isinstance(data, list)
    assert len(data) <= 20
    print("Test discover movies passed.")

def test_discover_tv(client):
    """Test the /discover route for TV shows."""
    rv = client.get('/discover?type=tv')
    assert rv.status_code == 200
    data = json.loads(rv.data)
    assert isinstance(data, list)
    assert len(data) <= 20
    print("Test discover TV shows passed.")

def test_discover_with_genre(client):
    """Test the /discover route with a genre filter."""
    rv = client.get('/discover?type=movie&genre=28')  # Assuming genre_id 28 is 'Action'
    assert rv.status_code == 200
    data = json.loads(rv.data)
    assert isinstance(data, list)
    assert len(data) <= 20
    for item in data:
        assert 28 in item['genre_ids']
    print("Test discover with genre passed.")

def test_update_popularity_success(client):
    """Test the /updatePopularity route with valid data."""
    rv = client.post('/updatePopularity', json={'movieId': '1', 'popularity': 99.5})
    assert rv.status_code == 200
    response_data = json.loads(rv.data)
    assert response_data['message'] == 'Popularity updated successfully'
    assert response_data['new_popularity'] == 99.5
    print("Test update popularity success passed.")

def test_update_popularity_invalid_movie(client):
    """Test the /updatePopularity route with an invalid movie ID."""
    rv = client.post('/updatePopularity', json={'movieId': '9999', 'popularity': 99.5})
    assert rv.status_code == 400
    response_data = json.loads(rv.data)
    assert 'error' in response_data
    assert response_data['error'] == 'Movie Id value not provided or not found'
    print("Test update popularity invalid movie passed.")

def test_update_popularity_invalid_value(client):
    """Test the /updatePopularity route with an invalid popularity value."""
    rv = client.post('/updatePopularity', json={'movieId': '1', 'popularity': 'invalid_value'})
    assert rv.status_code == 400
    response_data = json.loads(rv.data)
    assert 'error' in response_data
    assert response_data['error'] == 'Popularity value must be a float'
    print("Test update popularity invalid value passed.")

def test_status(client):
    """Test the /status route."""
    rv = client.get('/status')
    assert rv.status_code == 200
    assert rv.data == b'OK'
    print("Test status passed.")
