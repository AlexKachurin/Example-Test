# features/support/env.rb

require 'rest-client'
require 'active_support/all'
require_relative 'helpers/rest_wrapper'
require_relative 'helpers/logger'
require 'capybara/cucumber'
require 'selenium-webdriver'
require_relative 'helpers/class_extentions'
require 'rbconfig'   

def windows?
  !!(RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
end


def driver_name(base_name)
  windows? ? "#{base_name}.exe" : base_name
end


DOWNLOAD_PATH = 'C:/Users/User/OneDrive/Desktop/Ruby/candidate_test/features/download'
FileUtils.mkdir_p(DOWNLOAD_PATH) unless Dir.exist?(DOWNLOAD_PATH)

def browser_setup(browser = 'firefox')
  case browser
  when 'chrome'
    Capybara.register_driver :chrome do |app|
    
      Selenium::WebDriver::Chrome.driver_path = File.join('configuration', driver_name('chromedriver'))

      
      prefs = {
        'download.default_directory' => download_dir,
        'download.prompt_for_download' => false,
        'plugins.plugins_disabled' => ['Chrome PDF Viewer']
      }
      caps = Selenium::WebDriver::Remote::Capabilities.chrome(
        'chromeOptions' => {
          'args' => ['--window-size=1920,1080'],
          'prefs' => prefs
        }
      )
      Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: caps)
    end
    Capybara.default_driver = :chrome
    Capybara.page.driver.browser.manage.window.maximize
    Capybara.default_selector = :xpath
    Capybara.default_max_wait_time = 15
  else
    Capybara.register_driver :firefox_driver do |app|
   
      Selenium::WebDriver::Firefox.driver_path = File.join('configuration', driver_name('geckodriver'))

      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['browser.download.folderList'] = 2 
      profile['browser.download.dir'] = download_dir
      profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/octet-stream, text/xml'
      profile['pdfjs.disabled'] = true
      Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile, port: Random.rand(7000..7999))
    end
    Capybara.default_driver = :firefox_driver
  end
end


browser_setup('chrome')


configuration = YAML.load_file File.join('configuration', 'default.yml')
$rest_wrap = RestWrapper.new url: 'https://testing4qa.ediweb.ru/api',
                             **configuration[:credentials]
logger_initialize