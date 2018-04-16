require "selenium-webdriver"
require "io/console"

unless Dir.exists?('./parrots')
  puts "First, lets download all the parrots!"

  #!/usr/bin/env ruby
  `wget -q http://cultofthepartyparrot.com/parrots-37c2756949.zip`
  `unzip -q parrots-37c2756949.zip -d ./parrots/`
  `rm -rf parrots-37c2756949`

  puts "All set here, doctor!"
end

puts "\n\nPlease, insert your organization slack url: (w/ https) "
slack_path = gets.chomp

puts "\nInsert your user email"
slack_email = gets.chomp

puts "\nNow insert your super secret password"
slack_password = STDIN.noecho(&:gets).chomp

puts "Now that we have it all, lets do this! :fast_parrot:"

driver = Selenium::WebDriver.for :chrome
driver.navigate.to slack_path

driver.find_element(id: "email").send_keys(slack_email)
driver.find_element(id: "password").send_keys(slack_password)
driver.find_element(id: "signin_btn").click

begin
  puts "\nWrong email/password mate, try again please" if driver.find_element(class: 'alert_error').displayed?
rescue => NoSuchElementError
  puts "\nLogin has been successfully made, are you feeling the parrots already?? "
end

driver.quit
