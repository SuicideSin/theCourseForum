# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready () ->
  $('.course-professor-switcher').change () ->
    window.location.href='/course_professors?' + $(this).val()
  $('.review-type-switcher').change () ->
    window.location.href='/course_professors?' + $(this).val()
  $('#save-course').click () ->
    course = $(this).attr('data-course').split(' ')
    $.ajax "scheduler/course",
      type: "POST"
      data:
        mnemonic: course[0]
        number: course[1]
      success:
        alert('Course Saved!')