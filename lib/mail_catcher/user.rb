require "sqlite3"
require "active_support/json"




module MailCatcher::User extend self
  def user_db
      db_path ="#{Dir.home}/.mail_db"
      if !File.exists?("#{db_path}/user.db")
        Dir.mkdir(db_path) unless File.exists?(db_path)
        @__db ||= begin
          SQLite3::Database.new("#{db_path}/user.db", :type_translation => true).tap do |db|
            db.execute(<<-SQL)
              CREATE TABLE user (
                id INTEGER PRIMARY KEY ASC,
                name TEXT UNIQUE,
                password TEXT
              )
            SQL
            db.execute(<<-SQL)
              CREATE TABLE watchlist (
                id INTEGER PRIMARY KEY ASC,
                user_id INTEGER ,
                email_address TEXT  
              )
            SQL
            db.execute(<<-SQL)
              INSERT INTO user (name,password) 
              VALUES ("admin", "admin")
            SQL
          end
        end
      else
        @__db ||= SQLite3::Database.open("#{db_path}/user.db", :type_translation => true)
      end
  end

  def authorize(username,password)
    @user_query ||= user_db.prepare "SELECT id FROM user where name = ? AND password = ?"
    result = @user_query.execute(username,password).next
    if result
      return result[0]
    else
      return false
    end
  end

  def add_watch_email(user_id,email_address)
    @add_watch_email_query ||= user_db.prepare "INSERT INTO watchlist (user_id,email_address) SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM watchlist WHERE user_id =? and email_address = ? )"
    @add_watch_email_query.execute(user_id,email_address,user_id,email_address)
  end

  def get_user(user_id)
    @get_user_query ||= user_db.prepare "SELECT * from user where id = ?"
    row = @get_user_query.execute(user_id).next
    row && Hash[row.fields.zip(row)]
  end

  def delete_watch_email(watch_id)
    @delete_watch_email_query ||= user_db.prepare "DELETE FROM watchlist where id = ? "
    @delete_watch_email_query.execute(watch_id)
  end

  def add_user(username,password)
    @add_user_query ||= user_db.prepare "INSERT OR IGNORE  INTO user (name,password) VALUES (?,?)"
    @add_user_query.execute(username,password)
  end

  def update_user(user_id,password)
    @update_user_qury ||= user_db.prepare "UPDATE user SET password = ? where id = ?"
    @update_user_qury.execute(password,user_id)
  end

  def delete_user(user_id)
    @delete_user_query ||= user_db.prepare "DELETE FROM user where id = ?"
    @delete_user_watch_query ||= user_db.prepare "DELETE from watchlist where user_id = ?"
    @delete_user_query.execute(user_id) and
    @delete_user_watch_query.execute(user_id)
  end

  def get_user_list
    @get_user_list_query ||= user_db.prepare "SELECT * FROM user"
    @get_user_list_query.execute.map do |row|
      Hash[row.fields.zip(row)]
    end
  end

  def get_watch_list(user_id)
    @get_watch_list_query ||= user_db.prepare "SELECT id,email_address FROM watchlist where user_id = ?"
    @get_watch_list_query.execute(user_id).map do |row|
      Hash[row.fields.zip(row)]
    end
  end


end


