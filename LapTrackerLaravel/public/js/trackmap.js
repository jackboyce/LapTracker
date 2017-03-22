var map;
		    var count = 0;
		    var overlays = [];
		    var tracks = [];

		    function addOverlay(overlay) {
			overlays.push(overlay);
			overlay.setMap(map);
			//updateOverlays();
		    }

		    function httpGet(theUrl) {
			var xmlHttp = new XMLHttpRequest();
			xmlHttp.open( "GET", theUrl, false ); // false for synchronous request
			xmlHttp.send( null );
			return xmlHttp.responseText;
		    }

                    function httpGetAsync(theUrl, callback)
                    {
                        var xmlHttp = new XMLHttpRequest();
                        xmlHttp.onreadystatechange = function() {
                            if (xmlHttp.readyState == 4 && xmlHttp.status == 200)
                                callback(xmlHttp.responseText);
                        }
                        xmlHttp.open("GET", theUrl, true); // true for asynchronous
                        xmlHttp.send(null);
                    }

		    class Track {
			constructor(id, name, creator) {
                            this.id = id;
                            this.name = name;
                            this.creator = creator;
			    this.locations = [];

			    var rawLocations = httpGet("http://45.55.180.218/getLocationsForTrack?id=" + this.id);
                            var locationsArray = rawLocations.split("][");
                            locationsArray.pop();

                            var arrayOfArrayOfLocations = [];
                            for (var o in locationsArray) {
                                arrayOfArrayOfLocations.push(locationsArray[o].split(","));
                                this.locations.push({id: parseInt(arrayOfArrayOfLocations[o][0]), lat: parseFloat(arrayOfArrayOfLocations[o][1]), lng: parseFloat(arrayOfArrayOfLocations[o][2])});
                            }
                        }
		    }

		    function formPolyline(track) {
			console.log("Form polyline");
                        var latAndLong = [];

                        for (o in track.locations) {
                            latAndLong.push({lat: track.locations[o].lat, lng: track.locations[o].lng});
                        }
                        //latAndLong.shift();
                        console.log(latAndLong);
                        
                        var color;
                        console.log("Apply Polyline");

                        if (count % 3 == 0) {
                            color = '#FF0000';
                        } else if (count % 3 == 1) {
                            color = '#00FF00';
                        } else {
                            color = '#0000FF';
                        }

                        var polyline = new google.maps.Polyline({
                                                                  path: latAndLong,
                                                                  geodesic: true,
                                                                  strokeColor: color,
                                                                  strokeOpacity: 1.0,
                                                                  strokeWeight: 3
                                                                  });
                        
                        //flightPath.setMap(map);
                        addOverlay(polyline);
                        count += 1;
			google.maps.event.addListener(polyline, 'click', function() {
			    var rawTimes = httpGet("http://45.55.180.218/getTimesForTrack?id=" + track.id);
			    var splitTimes = rawTimes.split("][");
			    var splitSplitTimes = [];
			    var returnString = "";

			    for (o in splitTimes) {
				splitSplitTimes.push(splitTimes[o].split(","));
			    }
			    splitSplitTimes.pop();

			    splitSplitTimes.sort(function (a, b) { return (a[1] - b[1])});

			    for (o in splitSplitTimes) {
				returnString += (parseInt(o) + parseInt(1)) + ". " +  splitSplitTimes[o][1] + " " + splitSplitTimes[o][2] + "\n";
			    }

			    console.log(splitSplitTimes);
                            alert(returnString);
                            
                        });
		    }

		    function formPolylines() {
			for (value of tracks) {
			    formPolyline(value);
			}
		    }

                    function splitTracksArray(tracksSplit) {
                        //parse the tracks into different things based on the ,
                        console.log("Split Split Tracks");
                        var splitTracksSplit = [];
                        for (x in tracksSplit) {
                             splitTracksSplit.push(tracksSplit[x].split(","));
			     tracks.push(new Track(splitTracksSplit[x][0], splitTracksSplit[x][1], splitTracksSplit[x][2]));
                        }
                        console.log(splitTracksSplit);
                        //getLocationsForArrayOfArrays(splitTracksSplit);
			console.log(tracks);
			formPolylines();
                        //for all of the tracks get locations from track id
                    }

                    function splitTracks(rawTracks) {
                        //parse the tracks into different things based on the ][
                        console.log("Parse Tracks");
			console.log(rawTracks);
                        var tracksSplit = rawTracks.split("][");
                        tracksSplit.pop();
                        console.log(tracksSplit);
                        splitTracksArray(tracksSplit);
                    }

                    function loadTracks() {
                        console.log("load tracks");
                        httpGetAsync("http://45.55.180.218/getTracks", splitTracks);
                    }

                    function initMap() {
			map = new google.maps.Map(document.getElementById('map'), {
                                                      zoom: 12,
                                                      center: {lat: 38.897957, lng: -77.036560},
                                                      mapTypeId: 'terrain'
                                                      });
			navigator.geolocation.getCurrentPosition(function(position) {
                            var pos = {
                                lat: position.coords.latitude,
                                lng: position.coords.longitude
                                };

                            map.setCenter(pos);
                        }, function() {
                            //handleLocationError(true, infoWindow, map.getCenter());
                        });
                        loadTracks();
                    }


