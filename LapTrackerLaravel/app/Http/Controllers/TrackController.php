<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Requests;
use App\Track;
use App\Location;
use App\time;
use Illuminate\Support\Facades\Auth;

class TrackController extends Controller
{
    public function getUsernameFromID(Integer $id) {
        $users = DB::table('users')->get();
        foreach ($users as $user) {
            if($user->id == $id) {
                return $user->name;
            }
        }
        return 'none';
    }
    
    public function getTracks() {
        $tracks = DB::table('tracks')->get();
        $users = DB::table('users')->get();
        //return view('track.index', ['tracks' => $tracks]);
        foreach ($tracks as $track) {
            echo $track->id;
            echo ',';
            echo $track->name;
            echo ',';
            //echo $this->getUserFromID((int) ($track->createdby));
            foreach ($users as $user) {
                if($user->id == $track->createdby) {
                    echo $user->name;
                }
            }
            echo "][";
        }
    }
    
    public function getLocationsForTrack(Request $request) {
        $locations = DB::table('locations')->get();
        foreach ($locations as $location) {
            if($location->tracknumber == $request->id) {
                echo $location->id;
                echo ',';
                echo $location->latitude;
                echo ',';
                echo $location->longitude;
                echo "][";
            }
        }
    }
    
    public function getTimesForTrack(Request $request) {
        $times = DB::table('times')->get();
        foreach ($times as $time) {
            if($time->tracknumber == $request->id) {
                echo $time->id;
                echo ',';
                echo $time->time;
                echo ',';
                
                $users = DB::table('users')->get();
                foreach ($users as $user) {
                    if($user->id == $time->user) {
                        echo $user->name;
                    }
                }
                
                echo "][";
            }
        }
    }
    
    public function addLocation(Request $request) {
        $location = new location();
        $location->latitude = $request->latitude;
        $location->longitude = $request->longitude;
        $location->tracknumber = $request->tracknumber;
        $location->save();
    }

    public function addLocations(Request $request) {
        $string = $request->locations;
        $tracknumber = $request->tracknumber;
        $arr1 = explode("][", $string);

        foreach ($arr1 as &$value) {
            $arr2 = explode(",", $value);
            $location = new location();
            $location->latitude = $arr2[0];
            $location->longitude = $arr2[1];
            $location->tracknumber = $tracknumber;
            $location->save();
        }
    }
    
    public function addTime(Request $request) {
        $time = new time();
        $time->time = $request->time;
        $time->user = $request->user;
        $time->tracknumber = $request->tracknumber;
        $time->save();
    }
    
    public function addTrack(Request $request) {
        $track = new track();
        $track->name = $request->name;
        $track->createdby = $request->user;
        $track->save();
        return $track->id;
    }
    
    public function currentUserID()
    {
        if (Auth::check()) {
            $id = Auth::user()->id;
            return "$id";
        }
        return "none";
    }
    
    public function authStatus()
    {
        if (Auth::check()) {
            $email = Auth::user()->email;
            return "$email";
        }
        return "none";
    }
}
