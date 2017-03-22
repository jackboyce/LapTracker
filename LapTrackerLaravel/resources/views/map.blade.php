@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row">
        <div class="col-md-10 col-md-offset-1">
            <div class="panel panel-default">
                <div class="panel-heading">Map</div>

                <div class="panel-body">
		<head>
                    <style>
                    #map {
                    height: 500px;
                    width: 100%;
                    }
                    </style>
                    </head>
                    <body>
                    <div id="map"></div>
                    <script type="text/javascript" src="{{ URL::asset('js/trackmap.js') }}"></script>
                    <script async defer
                    src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBTC8p9uskB0CwuxMb-HbH-jRpTfMJOYhM&callback=initMap">
                    </script>
                    </body>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

