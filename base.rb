require 'selenium-webdriver'
require 'io/console'
require 'ruby-progressbar'

app_dir = File.expand_path(File.dirname(__FILE__))
parrots_dir = app_dir + '/parrots/'

unless Dir.exists?(parrots_dir)
  puts "First, lets download all the parrots!"

  `wget -q http://cultofthepartyparrot.com/parrots-7ee809e0f0.zip -P #{app_dir}`
  `unzip -q #{app_dir + '/parrots-7ee809e0f0.zip'} -d #{parrots_dir}`
  `cp -r #{parrots_dir + '/parrots'} #{app_dir} && rm -rf #{parrots_dir + '/parrots'} #{parrots_dir + '/hd'} `
  `rm -f #{app_dir + '/parrots-7ee809e0f0.zip'}`

  puts "All set here, doctor!\n\n"
end

puts "Please, insert your organization slack url:"
print "https://"
slack_path = "https://" + gets.chomp

puts "\nInsert your user email:"
slack_email = gets.chomp

puts "\nNow insert your super secret password"
slack_password = STDIN.noecho(&:gets).chomp

puts "\nNow that we have it all, lets do this! :fast_parrot:"

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')

# w3c:false is required for Chrome 75+
capabilities = { "chromeOptions" => {'w3c' => false} }

driver = Selenium::WebDriver.for :chrome, options: options, desired_capabilities: capabilities

wait = Selenium::WebDriver::Wait.new(:timeout => 15)

driver.navigate.to slack_path + '/customize/emoji'

password_field = driver.find_element(id: 'password')

driver.find_element(id: 'email').send_keys(slack_email)
password_field.send_keys(slack_password)
password_field.submit

begin
  abort('\nWrong email/password mate, try again please') if driver.find_element(class: 'alert_error').displayed?
rescue => NoSuchElementError
  puts "\nLogin has been successfully made, are you feeling the parrots already??\n\n"
end

parrots_with_directory = Dir.glob(parrots_dir + '*.gif')

progress_bar = ProgressBar.create(title: 'Parroting your slack!', total: parrots_with_directory.length, format: "\e[0;32m%t: |%B|\e[0m")

add_emoji_btn = wait.until {
    element = driver.find_element(class: "p-customize_emoji_wrapper__custom_button")
    element if element.displayed?
  }

parrots_with_directory.each do |parrot_with_directory|
  parrot_name = parrot_with_directory.gsub(parrots_dir, '')
  parrot_id = parrot_name.gsub(/.gif/, '').tr('-', '').split(/(?=parrot)/).join('-')
  progress_bar.title = parrot_name

  # skip if the account already has this emoji
  if driver.find_element(class: "p-customize_emoji_list__container").text.include?(":"+parrot_id+":")
    progress_bar.increment
    next
  end

  add_emoji_btn.click

  name_el = wait.until {
    element = driver.find_element(id: 'emojiname')
    element if element.displayed?
  }

  name_el.clear()
  name_el.send_keys(parrot_id)
  driver.find_element(id: 'emojiimg').send_keys(parrots_dir + parrot_name)
  driver.find_element(class: 'c-dialog__go').click

  sleep 2 # Wait image upload (this could take longer, change at your will)

  progress_bar.increment
end

`rm -rf #{parrots_dir}`

puts "Now your slack is parroted, thanks for using this tool."

driver.quit
