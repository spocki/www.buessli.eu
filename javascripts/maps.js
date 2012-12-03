function handleMaps() {
    $("table.map").each(function(){
	var gpx = $(this).attr("gpx");

	var json_name = gpx.replace(".gpx", "");
	var index = json_name.lastIndexOf("/");
	json_name = json_name.substr(index+1, json_name.length);
	json_name = json_name.replace("small.position", "latest.small");

	if (window.google === undefined) {
	    return;
	}
	var mapDiv = $(this).find("div.map");
	var profileDiv = $(this).find("div.map_profile");

	var mapId = "";
	if (mapDiv.length != 0) {
	   mapDiv = mapDiv[0];
	   mapId = $(mapDiv).attr("id");
	   var map = new google.maps.Map(mapDiv, {
	      mapTypeId: google.maps.MapTypeId.TERRAIN,
	      scaleControl: window.buessli.massstab,
	      overviewMapControl: window.buessli.massstab,
	      mapTypeId: "OSM",
          mapTypeControlOptions: {
              mapTypeIds: ["roadmap", "satellite", "hybrid", "terrain", "OSM", "OpenCycleMap"]
          }
	   });

	   if(false && window.buessli.maxzoom != 0) {
		   google.maps.event.addListener(map, 'zoom_changed', function() {
			   zoomChangeBoundsListener = google.maps.event.addListenerOnce(map, 'bounds_changed', function(event) {
				   if (this.getZoom() > window.buessli.maxzoom) {
					   this.setZoom(window.buessli.maxzoom);
				   }
			   });
			   setTimeout(function(){
				   google.maps.event.removeListener(zoomChangeBoundsListener);
			   },5000);
		 });
	   }

       map.mapTypes.set("OSM", new google.maps.ImageMapType({
           getTileUrl: function(coord, zoom) {
               return "http://tile.openstreetmap.org/" + zoom + "/" + coord.x + "/" + coord.y + ".png";
           },
           tileSize: new google.maps.Size(256, 256),
           name: "OpenStreetMap",
           maxZoom: 18
       }));

       map.mapTypes.set("OpenCycleMap", new google.maps.ImageMapType({
           getTileUrl: function(coord, zoom) {
               return "http://tile.opencyclemap.org/cycle/" + zoom + "/" + coord.x + "/" + coord.y + ".png";
           },
           tileSize: new google.maps.Size(256, 256),
           name: "OpenCycleMap",
           maxZoom: 18
       }));
	}
	$("#" + mapId).data("map", map);

	var infoWindow = new google.maps.InfoWindow();
    
	var profileId = "";
	if (profileDiv.length != 0) {
		profileId = $(profileDiv[0]).attr("id");
	    }

	var tracks_to_show = [];

	for (var counter = 0 ; counter < window.buessli.gpxtracks.length ; counter++) {
	    var gpx_track = window.buessli.gpxtracks[counter];
	    if (json_name === gpx_track["name"] || window.buessli.route) {
	    	tracks_to_show.push(gpx_track);
	    }
	}
        
	var points = [];
	var markers = [];
	var bounds = new google.maps.LatLngBounds ();
	var elevations = [];
	
	for (var track_counter = 0 ; track_counter < tracks_to_show.length ; track_counter++) {

		var first = true;
	    var track_to_show = tracks_to_show[track_counter];
	    
		var name = track_to_show["name"].replace("\.small", "").replace("_R", "").replace(".gpx", "");
		var index = name.lastIndexOf("/");
		name = name.substr(index+1, name.length);

	    for (var point_counter = 0 ; point_counter < track_to_show["points"].length ; point_counter++){
		var track_point = track_to_show["points"][point_counter];
		var lat = track_point["lat"];
		var lon = track_point["lon"];
		var ele = track_point["ele"] * 1;
		var data = {};
		data.y = ele;
		data.lat = lat;
		data.lon = lon;
		data.mapId = mapId;
		elevations.push(data);
		
		var p = new google.maps.LatLng(lat, lon);
		points.push(p);
		bounds.extend(p);
		
		var base = $("body").attr("base");
		var image = base + "/images/bus.png";
		
		if (first) {
		    first = false;
		    title = undefined;
		    if (name.match('^2')) {
			title = name;
		    }
		    
		    var marker = new google.maps.Marker({
			    map: map,
			    position: p,
			    title: title,
			    icon: image
			});
		
		    google.maps.event.addListener(marker, 'click', function () {
		    	var content = "";
				
		    	if (this.title.match('^2')) {
			    	var stamp = this.title.substring(0,10);
			    	var date = Date.parse(stamp);
					var stamp2 = date.add(1).days().toString("yyyy-MM-dd");
					var stamp3 = date.add(1).days().toString("yyyy-MM-dd");
					var popups = $('div[data-popup-name="' + stamp + '"]');
					for (var popupCounter = 0 ; popupCounter < popups.length ; popupCounter++)
					{
						var popup = popups[popupCounter];
						var images = $(popup).find("img[data-lazy-src]");
						for (var imagesCounter = 0 ; imagesCounter < images.length ; imagesCounter++)
						{
							var image = images[imagesCounter];
						    var src = $(image).attr("data-lazy-src");
							$(image).attr("src", src);
							$(image).parent().attr("target", "_top");
						}
						content = $(popup).html();
			    	};
				
						if (false) {
				var stamp = this.title.substring(0,10);
				var date = Date.parse(stamp);
				var stamp2 = date.add(1).days().toString("yyyy-MM-dd");
				var stamp3 = date.add(1).days().toString("yyyy-MM-dd");
				var blogs = window.buessli.blog;
				for (index = 0 ; index < blogs.length ; index++) {
				    var blog = blogs[index];
				    if (blog.date === stamp || blog.date === stamp2 || blog.date === stamp3) {
					content += "<a href=\"";
					content += blog.url;
					content += "\">";
					content += blog.title;
					content += "</a><br>";
				    }
				}
				var picasa = window.buessli.picasa;
					for (index = 0 ; index < picasa.length ; index++) {
						var album = picasa[index];
						if (album["name"].match('^' + stamp)) {
							var pictures = album.pictures;
							content += "<br>";
							var max = 6;
							if (pictures.length < max) {
								max = pictures.length;
							}
							for (counter = 0 ; counter < max ; counter++) {
								content += "<a target=\"_top\" href=\"";
								content += "https://picasaweb.google.com/" + pictures[counter].link;
								content += "\">";
								content += "<img src=\"";
								content += pictures[counter].url.replace(/s220-c/, "s60-c");
								content += "\"></a>&nbsp;";
							}
						}	
					}
					
						}
			    
					
				if (content !== "") {
				    var html = "<div class=\"infowindow\">"; 
				    html += "<h3>";
				    html += stamp;
				    html += "</h3>";
				    html += content;
				    html += "</div>";
				    infoWindow.setContent(html);
				    infoWindow.open(map, this);
				}
			    }
			});
		    markers.push(marker);
		}
	    }
	}
	
	if (profileId !== "") {
	    drawChart(profileId, name, elevations);
	}	
	
        // 237024
        var color = "#237024";
	var poly = new google.maps.Polyline({
		// use your own style here
		path: points,
		strokeColor: color,
		strokeOpacity: .7,
		strokeWeight: 4
	    });
	
	poly.setMap(map);
	map.fitBounds(bounds);
    // if (json_name.indexOf("latest") !== -1) {
	//    map.setZoom(3);
	// }
	});
}

$(document).ready(function(){
    handleMaps();
});

var drawChart = function(id, title, elevations){
    var elevationsReduced = [];
    var div = Math.round(elevations.length / 50);  
    for (index = 0; index < elevations.length ; index = index + div){
	elevationsReduced.push(elevations[index]);
    }
    var length = elevationsReduced.length;
    var chart = new Highcharts.Chart({
	    chart: {
		renderTo: id,
		type: 'line'
	    },
	    colors: [
		     '#DCA826', 
		     '#DCA826', 
		     '#DCA826', 
		     '#DCA826', 
		     '#DCA826'
		     ],
	    legend: {
                enabled: false
            },
            title: {
                text: title
            },
            yAxis: {
		title: {
		    text: 'Meter'
		},
		plotLines: [{
			value: 0,
			width: 1
		    }]
	    },
	    xAxis: {
            labels:
            {
                enabled: false
            }
        },
        tooltip: {
		formatter: function() {
		    var mapId = this.point.mapId;
		    var lat = this.point.lat;
		    var lon = this.point.lon;
		    var map = $("#" + mapId).data("map");
		    var markers = $("#" + mapId).data("markers");
		    if (markers == undefined) {
			markers = [];
		    }
		    var p = new google.maps.LatLng(lat, lon);
		    var base = $("body").attr("base");
		    var image = base + "/images/bus_l.png"
		    var marker = new google.maps.Marker({
			map: map,
			position: p,
			icon: image
			});
		    for (index = 0; index < markers.length ; index++) {
			markers[index].setMap(null);
		    }
		    markers.push(marker);
		    $("#" + mapId).data("markers", markers);
		    return Math.round(this.y) +' Meter';
		}
	    },
	    series: [{
		    data: elevationsReduced
		}]
	});
    return chart;
} 
