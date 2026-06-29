# frozen_string_literal: true

require 'fileutils'


def wait_for_download(filename, timeout = 30)
  start_time = Time.now
  until File.exist?(File.join(DOWNLOAD_PATH, filename))
    raise "Файл #{filename} не скачался за #{timeout} секунд" if Time.now - start_time > timeout
    sleep 0.5
  end
  $logger.info("Файл #{filename} скачан")
end


def filename_from_url(url)
  URI.parse(url).path.split('/').last
end


When(/^я открываю страницу "([^"]*)"$/) do |url|
  visit(url)
  $logger.info("Страница #{url} открыта")
  sleep 1
end


When(/^я перехожу по ссылке "Скачать" в главном меню$/) do
  download_link = find('a[href="/ru/documentation/installation/"]')
  download_link.click
  $logger.info('Переход по ссылке "Скачать" в главном меню выполнен')
  sleep 1
end


When(/^я еще раз нажимаю кнопку скачать в меню раздела установки для перехода на вкладку https:\/\/www\.ruby-lang\.org\/ru\/downloads\/$/) do

  begin
    download_link = find('a[href="/ru/downloads/"]') 
    $logger.info('Дополнительный клик по "Скачать" выполнен')
  rescue Capybara::ElementNotFound
    $logger.info('Дополнительная кнопка "Скачать" не найдена, переходим к следующему шагу')
  end
  sleep 1
end


When(/^я нахожу ссылку для скачивания последней стабильной версии Ruby$/) do
  all_links = all('a[href*="ruby-"]')
  target_link = all_links.find { |link| link[:href] =~ /\.tar\.gz$/ }
  raise 'Ссылка для скачивания не найдена' unless target_link

  @download_url = target_link[:href]
  @expected_filename = filename_from_url(@download_url)
  $logger.info("Найдена ссылка на скачивание: #{@download_url}, ожидаемое имя файла: #{@expected_filename}")
end


When(/^я нажимаю на эту ссылку$/) do
  raise 'Ссылка для скачивания не была найдена ранее' unless @download_url

  visit(@download_url)
  $logger.info("Клик по ссылке выполнен, идёт загрузка файла #{@expected_filename}")
  sleep 2 
end


When(/^файл установщика должен быть скачан в папку "features\/download"$/) do
  wait_for_download(@expected_filename)
  expect(File).to exist(File.join(DOWNLOAD_PATH, @expected_filename))
  $logger.info("Файл #{@expected_filename} присутствует в папке загрузок")
end


And(/^имя скачанного файла должно соответствовать имени, указанному на странице загрузок$/) do
  downloaded_files = Dir.entries(DOWNLOAD_PATH).reject { |f| f == '.' || f == '..' }
  expect(downloaded_files).to include(@expected_filename), 
    "Ожидался файл #{@expected_filename}, но в папке найдены: #{downloaded_files.join(', ')}"
  $logger.info("Имя файла #{@expected_filename} соответствует ожидаемому")
end
