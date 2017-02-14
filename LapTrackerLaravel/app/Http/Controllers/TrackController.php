<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Requests;
use App\track;
use App\location;
use Illuminate\Support\Facades\Auth;

class TrackController extends Controller
{
    public function getTracks() {
        $tracks = DB::table('tracks')->get();
        
        $users = DB::table('users')->get();
        //return view('track.index', ['tracks' => $tracks]);
        foreach ($tracks as $track) {
            echo $track->id;
            echo ' ';
            echo $track->name;
            echo ' ';
            //echo $this->getUserFromID((int) ($track->createdby));
            foreach ($users as $user) {
                if($user->id == $track->createdby) {
                    echo $user->name;
                }
            }
            echo "<html><br></html>";
        }
    }
    
    public function getLocationsForTrack(Request $request) {
        $locations = DB::table('locations')->get();
        foreach ($locations as $location) {
            if($location->tracknumber == $request->id) {
                echo $location->latitude;
                echo ' ';
                echo $location->longitude;
                echo "<html><br></html>";
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
    /*
    public function getUserFromID(Integer $lookingID) {
        $users = DB::table('users')->get();
        foreach ($users as $user) {
            if($user->id == $lookingID) {
                return $user->name;
            }
        }
        return 'none';
    }*/
    
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
