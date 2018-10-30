When /^I write a review/ do
  select "Computer Science (CS)", :from => 'subdept_select'
  select "CS 2150", :from => 'course_select'
  puts "#{Professor.first.last_name}, #{Professor.first.first_name}"
  select "Bloomfield, Aaron", :from => 'prof_select'
  select "Fall", :from => 'semester_season'
  select "2018", :from => 'semester_year'
  page.execute_script("$('.prof-rating-slider').slider('value', 1)")
  # decided that 'enjoyability' slider was no-longer needed
  #page.execute_script("$('.enjoyability-slider').slider('value', 2)")
  page.execute_script("$('.recommend-slider').slider('value', 4)")
  fill_in('review_comment', :with => "Test Review")
  fill_in('readingfield', :with => "1")
  # decided that the 'readingfield' field would be treated like 'totalfield' (removed the others)
  #fill_in('writingfield', :with => "1")
  #fill_in('homeworkfield', :with => "1")
  #fill_in('groupfield', :with => "1")
  click_button("Submit Review")
end

When /^I edit a review/ do
  fill_in('review_comment', :with => 'NEW TEXT')
  select "2018", :from => 'semester_year'
  select "Fall", :from => 'semester_season'
  click_button("Submit Review")
end
