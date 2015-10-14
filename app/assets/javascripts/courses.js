var ready;

ready = function() {

	function sortProfessors(selector, attrName) {

		return $($(selector).toArray().sort(function(a, b) {	

			// Get stat to sort by (rating, difficulty, gpa)
			var aVal = parseFloat($(a).find(attrName).text()),
    			bVal = parseFloat($(b).find(attrName).text());            
    		var retVal = bVal - aVal;

	   		// Handle no stat
	   		if (isNaN(aVal) && !isNaN(bVal)) { 	   			
	   			return 1;
	   		} else if (isNaN(bVal) && !isNaN(aVal)) {
	   			return -1;
	   		} else if (isNaN(bVal) && isNaN(aVal)) {
	   			retVal = 0;
	   		}
		    
	    	// Sort difficulty ascending
	    	if (attrName == ".course-difficulty") {
	    		retVal = retVal * -1;
	    	}

	    	// Handle tie
	    	if (retVal == 0) {
	    		var otherSortOptions = [".course-rating", ".course-difficulty", ".course-gpa"];   

	    		for(var i = 0; i < otherSortOptions.length; i++) {
	    			// Get another stat
	    			if(attrName != otherSortOptions[i]) {		    			
	    				var aVal = parseFloat($(a).find(otherSortOptions[i]).text()),
    						bVal = parseFloat($(b).find(otherSortOptions[i]).text());            
    					var retVal = bVal - aVal;

    					// Handle no stat
				   		if (isNaN(aVal) && !isNaN(bVal)) { 	   			
				   			return 1;
				   		} else if (isNaN(bVal) && !isNaN(aVal)) {
				   			return -1;
				   		} else if (isNaN(bVal) && isNaN(aVal)) {
				   			retVal = 0;
				   		}
			   			// stop if found a tie breaker
		    			if (retVal != 0) {
		        			break;	
		        		}
		        		// if three-way tie
		        		if (i == 2 && retVal == 0) {
		        			return 0;
		        		}
	        		}
	        	}      		
	    	}

	    	return retVal;

		}));
	}	
	

	// Sort professors by stats
	$('#prof-sort').change(function() {		

		// id of stat to sort by		
		var sortString = ".course-" + $(this).find('.active')[0].id;
		// class of which panels are displayed (current semester or all)
		var selectorString = $("#all").parent().hasClass("active") ? ".prof-panel.all" : ".prof-panel.current";
		// how many panels there are (to know when to trigger the next animation)
		var numPanels = $(selectorString).length;
		var slidPanels = 0;		
		// sorted list of professors
		var profList = sortProfessors($(".prof-panel"), sortString);					
		// slide up all the panels. then, on complete, add the sorted ones and slide down what is needed.
		$(selectorString).slideUp(350, function() {			
			slidPanels++;
			if(slidPanels == numPanels) {
				$(".prof-panel-container").empty();
				$(".prof-panel-container").append(profList);
				$(selectorString).slideDown(350);
			}			
		});			
	});



	$('#main-container').scroll(function() {
		if ($('#main-container').prop('scrollHeight') - $('#main-container').scrollTop() <= $('#main-container').height() + 100) {
			appendReviews();
		}
	});

	var params, search, amount, lastIndex;
	var reviews;

	// load 10 reviews at a time
	amount = 10;

	if (window.location.search != '') {
		search = window.location.search.substring(1);
		params = JSON.parse('{"' + search.replace(/=/g, '":"').replace(/&/g, '","') + '"}');
		if (params['p']) {
			$('#check-' + params['p']).prop('checked', true);
		}
	}

	function loadReviews(sortType) {
		// get the params
		var courseUrl = window.location.pathname.substring(1);
		courseId = courseUrl.substring(courseUrl.search('/') + 1);
		// default sort is recent
		sortType = sortType ? sortType : "recent";

		$.ajax('/courses/reviews', {
			method: "GET",
			data: {
				course_id: courseId,
				professor_id: params ? params['p'] : undefined,
				sort_type: sortType,
			},
			success: function(response) {
				$('.reviews-box').append(response);
				$('[id^="vote_up_"]').click(voteUp);
				$('[id^="vote_down_"]').click(voteDown);
				appendReviews();
			}
		});

	}


	function appendReviews() {
		var index = 0;
		$('.reviews-box').children('.hidden').each(function(review) {
			if (index <= amount) {
				index++;
				($(this).removeClass('hidden'));
			} else {
				return;
			}
		});
	}

	$('.courses-review-type-switcher').change(function() {

		// clear out the reviews (but keep the hidden template one)
		reviews = [];
		$('.reviews-box').empty();
		// set the sort type based on the selected value
		var dropdownVal = $(this).val();

		//load and insert the reviews
		loadReviews(dropdownVal);

	});

	$('#save-course-button').click(function() {
		var course_name = $('#course-name').text().replace(/^\s\s*/, '').replace(/\s\s*$/, '');
		course_name = course_name.split(' - ');
		course_name = course_name[0].split(' ');

		if ($('#save-course-button').text().trim() == 'Unsave') {
			$('#save-course-button').text("Save Course");

			$.ajax('/scheduler/unsave_course', {
				method: "POST",
				data: {
					mnemonic: course_name[0],
					course_number: course_name[1]
				},
				success: function(response) {
					// alert('Course saved for scheduler!');
				},
				failure: function(response) {
					console.log('Could not load corresponding course!');
				}
			});
		} else {
			$('#save-course-button').text("Unsave");
			$.ajax('/scheduler/course', {
				method: "POST",
				data: {
					mnemonic: course_name[0],
					course_number: course_name[1]
				},
				success: function(response) {
					// alert('Course saved for scheduler!');
				},
				failure: function(response) {
					console.log('Could not load corresponding course!');
				}
			});
		}

	});


	$('.skillbar').each(function() {
		$(this).find('.skillbar-bar').animate({
			width: $(this).attr('data-percent')
		}, 1000);
	});

	try {
		$('.carousel').slick({
			infinite: true,
			slidesToShow: 2,
			slidesToScroll: 2,
			dots: true,
			responsive: [{
					breakpoint: 1120,
					settings: {
						slidesToShow: 1,
						slidesToScroll: 1,
						infinite: true,
						dots: true
					}
				},
				// {
				//   breakpoint: 00,
				//   settings: {
				//     slidesToShow: 1,
				//     slidesToScroll: 1
				//   }
				// },
			],
		});
	} catch (error) {
		console.log(error);
	}

	$("#courses-sidebar").css("height", $("#courses-main").height());

	voteUp = function() {
		var review_id = this.id.match(/\d+/)[0];

		if ($("#vote_up_" + review_id).css("opacity") == 1) {
			$.ajax({
				url: '/unvote/' + review_id,
				type: 'POST',
				success: function() {
					$("#vote_up_" + review_id).removeClass("vote-active");
					var count = $("#votes_" + review_id).text().trim();
					count = parseInt(count) - 1;
					$("#votes_" + review_id).text(count);
				}
			});
		} else {
			$.ajax({
				url: '/vote_up/' + review_id,
				type: 'POST',
				success: function() {
					var wasDownvoted = $("#vote_down_" + review_id).hasClass("vote-active");

					$("#vote_up_" + review_id).addClass("vote-active");
					$("#vote_down_" + review_id).removeClass("vote-active");

					var count = $("#votes_" + review_id).text().trim();
					if (count == "") {
						count = 1
					} else if (wasDownvoted) {
						count = parseInt(count) + 2;
					} else {
						count = parseInt(count) + 1;
					}

					$("#votes_" + review_id).text(count);


				}
			});
		}
	}

	voteDown = function() {
		var review_id = this.id.match(/\d+/)[0];

		if ($("#vote_down_" + review_id).css("opacity") == 1) {
			$.ajax({
				url: '/unvote/' + review_id,
				type: 'POST',
				success: function() {
					$("#vote_down_" + review_id).removeClass("vote-active");
					var count = $("#votes_" + review_id).text().trim();
					count = parseInt(count) + 1;
					$("#votes_" + review_id).text(count);
				}
			});
		} else {
			$.ajax({
				url: '/vote_down/' + review_id,
				type: 'POST',
				success: function() {

					var wasUpvoted = $("#vote_up_" + review_id).hasClass("vote-active");
					$("#vote_down_" + review_id).addClass("vote-active");
					$("#vote_up_" + review_id).removeClass("vote-active");

					var count = $("#votes_" + review_id).text().trim();
					if (count == "") {
						count = -1
					} else if (wasUpvoted) {
						count = parseInt(count) - 2;
					} else {
						count = parseInt(count) - 1;
					}

					$("#votes_" + review_id).text(count);
				}
			});
		}
	}
	loadReviews($('.courses-review-type-switcher').val());
}

$(document).ready(ready);

$(document).on('page:load', ready);