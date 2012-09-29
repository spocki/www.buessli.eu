var alben = {};

$(document).ready(function() {
    $("table[data-title]").each(function() {
    	var table = $(this);
    	var title = table.attr("data-title");
    	for (album_counter = 0 ; album_counter < window.buessli.picasa.length ; album_counter++) {
    		var picasa_album = window.buessli.picasa[album_counter];
    		if (picasa_album["name"] === title) {
    			log("Found: " + title);
    			table.data("album", picasa_album);
    			setTimeout(function() {
    				switchPictures(table);
    			}, getRandomTime());
    		}
    	}
    });
});

var headerPictureCounter = 0;

var log = function(message) {
    // console.log(message);
}

var switchPictures = function(table) {
    var album = $(table).data("album");
    var title = $(table).attr("data-title");
    var images = $(table).find("img");
    var tds = $(table).find("td");
    
    if (album.pictures.length > images.length) {
	var nextPictureReplacement = $(table).data("nextPictureReplacement");
	if (nextPictureReplacement === undefined) {
	    nextPictureReplacement = 0;
	} else {
	    nextPictureReplacement = (++nextPictureReplacement) % images.length;
	}
	log("nextPictureReplacement " + nextPictureReplacement);
	$(table).data("nextPictureReplacement", nextPictureReplacement);
	
	var nextPicture = $(table).data("nextPicture");
	if (nextPicture === undefined) {
	    var dataOffset = $(table).attr("data-offset");
	    if (dataOffset === undefined) {
		dataOffset = images.length + 1;
	    } else {
		dataOffset = dataOffset % album.pictures.length; 
	    }
	    nextPicture = dataOffset;
	} else {
	    nextPicture = (++nextPicture) % album.pictures.length;
	}
	log("nextPicture " + nextPicture);
	$(table).data("nextPicture", nextPicture);
	
	var td = tds[nextPictureReplacement];
	var img = $(td).find("img");

	var picture = album.pictures[nextPicture];
	
	log(td);
	log(img);
	
	var newImg = $("<img src=\"" + picture.url+ "\">");
	newImg.load(function(){
	    $(img).css("z-index", "1000");
	    img.after(newImg);
	    $(img).fadeOut(2000, function() {
		$(img).remove();
		$(td).find("a").attr("href", picture.link);
		setTimeout(function() {
		    switchPictures(table);
		}, getRandomTime());
	    });
	});
    }
}

function getRandomTime() {
    var randomTime = Math.floor(2000 * Math.random());
    randomTime += 2000;
    return randomTime;
}
