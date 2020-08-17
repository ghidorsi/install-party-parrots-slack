require 'selenium-webdriver'
require 'io/console'
require 'io/console'
require 'ruby-progressbar'

app_dir = File.expand_path(File.dirname(__FILE__))
parrots_dir = app_dir + '/parrots/'

unless Dir.exists?(parrots_dir)
  puts "First, lets download all the parrots!"

  `wget -q https://cultofthepartyparrot.com/parrots-fc0dac9ef3.zip -P #{app_dir}`
  `unzip -q #{app_dir + '/parrots-fc0dac9ef3.zip'} -d #{app_dir}`
  `cp -r #{parrots_dir + '/hd/.'} #{parrots_dir} && rm -rf #{parrots_dir + '/hd'}`
  `rm -f #{app_dir + '/parrots-fc0dac9ef3.zip'}`

  puts "All set here, doctor!\n\n"
end

puts "Please, insert your organization slack url:"
print "https://"
slack_path = 'https://' + gets.chomp

puts "\nInsert your user email:"
slack_email = gets.chomp

puts "\nNow insert your super secret password"
slack_password = IO::console.getpass

puts "\nNow that we have it all, lets do this! :fast_parrot:"

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')

# w3c:false is required for Chrome 75+
capabilities = { "chromeOptions" => {'w3c' => false} }

driver = Selenium::WebDriver.for :chrome, options: options, desired_capabilities: capabilities

wait = Selenium::WebDriver::Wait.new(:timeout => 45)

driver.navigate.to slack_path + '/customize/emoji'

password_field = driver.find_element(id: 'password')

driver.find_element(id: 'email').send_keys(slack_email)
password_field.send_keys(slack_password)
password_field.submit

abort('\nWrong email/password mate, try again please') if driver.find_elements(id: 'password_error').any?

puts "\nLogin has been successfully made, are you feeling the parrots already??\n\n"

parrots_with_directory = Dir.glob(parrots_dir + '*.gif')

progress_bar = ProgressBar.create(title: 'Parroting your slack!', total: parrots_with_directory.length, format: "\e[0;32m%t: |%B|\e[0m")

add_emoji_btn_lambda = -> do
    wait.until {
      element = driver.find_element(xpath: "//button[@data-qa='customize_emoji_add_button']")
      element if element.displayed?
    }
  end

add_emoji_btn_lambda.call

parrots_with_directory.each do |parrot_with_directory|
  wait.until { 
    if driver.find_elements(xpath: "//div[@data-qa='customize_emoji_add_dialog_error']").any? || driver.find_elements(id: 'emojiname_error').any?
      driver.find_element(xpath: "//button[@data-qa='sk_close_modal_button']").click
    end

    driver.find_elements(class: 'c-sk-modal_portal').none? 
  }

  parrot_name = parrot_with_directory.gsub(parrots_dir, '')
  parrot_id = parrot_name.gsub(/.gif/, '').tr('-', '').split(/(?=parrot)/).join('-')
  progress_bar.title = parrot_name

  add_emoji_btn_lambda.call.click

  name_el = wait.until {
    element = driver.find_element(id: 'emojiname')
    element if element.displayed?
  }

  name_el.clear()
  name_el.send_keys(parrot_id)
  driver.find_element(id: 'emojiimg').send_keys(parrots_dir + parrot_name)

  begin
    driver.find_element(xpath: "//button[@data-qa='customize_emoji_add_dialog_go']").click    
  rescue => exception
    sleep 2
    driver.find_element(xpath: "//button[@data-qa='customize_emoji_add_dialog_go']").click
  end

  progress_bar.increment
end

`rm -rf #{parrots_dir}`

puts "Now your slack is parroted, thanks for using this tool."

driver.quit
