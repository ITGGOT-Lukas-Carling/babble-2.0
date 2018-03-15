class App < Sinatra::Base
	enable	:sessions
	log_username = ""
	log_error = ""
	username = "HELLO"

	set :server, 'thin'
	set :sockets, []


	# get('/ws') do
	# 	if session[:username].to_s==""
	# 		username ="guest"
	# 	else
	# 		username = session[:username].to_s
	# 	end
	# 	if !request.websocket?
	# 	  erb(:chat)
	# 	else
	# 	  request.websocket do |ws|
	# 		ws.onopen do
	# 		  ws.send("Hello World!")
	# 		  settings.sockets << ws
	# 		end
	# 		ws.onmessage do |msg|
	# 		  send = session[:username].to_s+": " + msg
	# 		  EM.next_tick { settings.sockets.each{|s| s.send(send) } }
	# 		end
	# 		ws.onclose do
	# 		  warn("websocket closed")
	# 		  settings.sockets.delete(ws)
	# 		end
	# 	  end
	# 	end
	#   end
	  
	
	get('/home') do
		erb(:test)
	end


	get('/index') do
		if session[:username].to_s==""
			username ="guest"
		else
			username = session[:username].to_s
		end
		if !request.websocket?
		  erb(:index)
		else
		  request.websocket do |ws|
			ws.onopen do
			  ws.send("Hello World!")
			  settings.sockets << ws
			end
			ws.onmessage do |msg|
			  send = session[:username].to_s + ": " + msg
			  EM.next_tick { settings.sockets.each{|s| s.send(send) } }
			end
			ws.onclose do
			  warn("websocket closed")
			  settings.sockets.delete(ws)
			end
		  end
		end
	end



	get('/') do
		redirect('/index') 
	end

	get('/login') do
		slim(:login, locals:{username:log_username, error:log_error})
	end

	get('/register') do
		slim(:register, locals:{username:log_username, error:log_error})
	end

	post('/register') do
		db = SQLite3::Database.new("db/users.sqlite")
		reg_username = params["reg-username"]
		reg_password1 = params["reg-password1"]
		reg_password2 = params["reg-password2"]
		if reg_password1 == reg_password2
			reg_password = reg_password1
			usernames = db.execute("SELECT username FROM users").join(" ").split(" ")
			p usernames
			if !usernames.include?(reg_username)
				crypt_password = BCrypt::Password.create(reg_password)
				db.execute("INSERT INTO users('username', 'password') VALUES(?, ?)", [reg_username, crypt_password])
				log_error = ""
			else
				log_error = "That username already exists"
			end
		else
			log_error = "Passwords do not match"
			redirect('/register')
		end
		session[:logged] = true
		session[:username] = reg_username
		log_error = ""
		redirect('/')
	end

	post('/login') do
		db = SQLite3::Database.new("db/users.sqlite")
		log_username = params["log-username"]
		log_password = params["log-password"]
		password = db.execute("SELECT password FROM users WHERE username IS '#{log_username}'")
		if password[0] == nil
			log_error = "Wrong username or password"
			redirect('/login')
		else
			password_digest = BCrypt::Password.new(password[0][0])
			if  password_digest == log_password
				session[:logged] = true
				session[:username] = log_username
				session[:online] = true
				log_error = ""
			else
				log_error = "Wrong username or password"
				redirect('/login')
			end
		redirect('/')
		end
	end

	post('/logout') do
		log_error = ""
		session[:logged] = false
		session[:online] = false
		session[:username] = "guest"
		redirect('/login')
	end


end           
