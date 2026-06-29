# frozen_string_literal: true

м
def user_id_by_login(login)
  return @scenario_data.users_id[login] if @scenario_data.users_id.key?(login)

  if @scenario_data.users_full_info.nil?
    @scenario_data.users_full_info = $rest_wrap.get('/users')
    $logger.info('Информация о пользователях получена (автоматически)')
  end

  
  user_id = find_user_id(users_information: @scenario_data.users_full_info, user_login: login)
  @scenario_data.users_id[login] = user_id if user_id
  user_id
end

When(/^получаю информацию о пользователях$/) do
  users_full_information = $rest_wrap.get('/users')

  $logger.info('Информация о пользователях получена')
  @scenario_data.users_full_info = users_full_information
end

When(/^проверяю (наличие|отсутствие) логина (\w+\.\w+) в списке пользователей$/) do |presence, login|
  search_login_in_list = true
  presence == 'отсутствие' ? search_login_in_list = !search_login_in_list : search_login_in_list

  logins_from_site = @scenario_data.users_full_info.map { |f| f.try(:[], 'login') }
  login_presents = logins_from_site.include?(login)

  if login_presents
    message = "Логин #{login} присутствует в списке пользователей"
    search_login_in_list ? $logger.info(message) : raise(message)
  else
    message = "Логин #{login} отсутствует в списке пользователей"
    search_login_in_list ? raise(message) : $logger.info(message)
  end
end

When(/^добавляю пользователя c логином (\w+\.\w+) именем (\w+) фамилией (\w+) паролем ([\d\w@!#]+)$/) do
|login, name, surname, password|

  response = $rest_wrap.post('/users', login: login,
                                       name: name,
                                       surname: surname,
                                       password: password,
                                       active: 1)
  $logger.info(response.inspect)
end

When(/^добавляю пользователя с параметрами:$/) do |data_table|
  user_data = data_table.raw

  login = user_data[0][1]
  name = user_data[1][1]
  surname = user_data[2][1]
  password = user_data[3][1]

  step "добавляю пользователя c логином #{login} именем #{name} фамилией #{surname} паролем #{password}"
end

When(/^нахожу пользователя с логином (\w+\.\w+)$/) do |login|
  step %(получаю информацию о пользователях)
  if @scenario_data.users_id[login].nil?
    @scenario_data.users_id[login] = find_user_id(users_information: @scenario_data
                                                                         .users_full_info,
                                                  user_login: login)
  end

  $logger.info("Найден пользователь #{login} с id:#{@scenario_data.users_id[login]}")
end
# Удаление пользователя по логину - мои шаги
When(/^удаляю пользователя с логином (\w+\.\w+)$/) do |login|
  user_id = user_id_by_login(login)
  if user_id.nil?
    raise "Пользователь с логином #{login} не найден, невозможно удалить"
  end

  response = $rest_wrap.delete("/users/#{user_id}")

 
  unless response.code >= 200 && response.code < 300
    raise "Ошибка при удалении пользователя #{login} (id:#{user_id}), код ответа: #{response.code}, тело: #{response.body}"
  end

  $logger.info("Удалён пользователь #{login} (id:#{user_id}), ответ: #{response.inspect}")


  @scenario_data.users_id.delete(login)
  @scenario_data.users_full_info = nil  
end

# Изменение параметров пользователя по логину - мои шаги
When(/^изменяю пользователя с логином (\w+\.\w+) параметры:$/) do |login, data_table|
  user_id = user_id_by_login(login)
  if user_id.nil?
    raise "Пользователь с логином #{login} не найден, невозможно изменить"
  end

  params = {}
  data_table.raw.each do |row|
    key = row[0].strip
    value = row[1].strip

    value = value.to_i if key == 'active'
    params[key.to_sym] = value
  end

  response = $rest_wrap.put("/users/#{user_id}", params)

  unless response.code >= 200 && response.code < 300
    raise "Ошибка при изменении пользователя #{login} (id:#{user_id}), код ответа: #{response.code}, тело: #{response.body}"
  end

  $logger.info("Изменён пользователь #{login} (id:#{user_id}), новые параметры: #{params.inspect}, ответ: #{response.inspect}")


  if params.key?(:login) && params[:login] != login
    @scenario_data.users_id[params[:login]] = user_id
    @scenario_data.users_id.delete(login)
  end

 
  @scenario_data.users_full_info = nil
end