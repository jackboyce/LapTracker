<?php

/*
|--------------------------------------------------------------------------
| Application Routes
|--------------------------------------------------------------------------
|
| Here is where you can register all of the routes for an application.
| It's a breeze. Simply tell Laravel the URIs it should respond to
| and give it the controller to call when that URI is requested.
|
*/

Route::get('/', function () {
    return view('home');
});

Route::auth();

Route::get('/home', 'HomeController@index');
Route::get('/map', 'HomeController@map');
Route::get('/getTracks', 'TrackController@getTracks')->middleware('auth');
//Route::post('/addTrack', ['middleware' => 'auth', 'uses' => 'TrackController@addTrack']);
Route::post('/addTrack', 'TrackController@addTrack')->middleware('auth');
Route::get('/getLocationsForTrack', 'TrackController@getLocationsForTrack')->middleware('auth');
Route::post('/addLocation', 'TrackController@addLocation')->middleware('auth');
Route::post('/addLocations', 'TrackController@addLocations')->middleware('auth');
Route::get('/authStatus', 'TrackController@authStatus');
Route::get('/currentUserID', 'TrackController@currentUserID');
Route::post('/addTime', 'TrackController@addTime')->middleware('auth');
Route::get('/getTimesForTrack', 'TrackController@getTimesForTrack')->middleware('auth');
