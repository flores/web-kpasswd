#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'rack'
require 'haml'
require 'base64'

def authenticate()
	user_env = @env["Authorization"] || @env["HTTP_AUTHORIZATION"]
        if user_env
                user = Base64.decode64(user_env[6,user_env.length-6])[/\w+/]
		return user
        else
        	return nil
	end
end

set :environment, :production
set :bind, 'localhost'

get '/' do
	redirect '/changepw'
end

get '/unauthenticated' do
	"Unfortunately we could not authenticate you.  Please contact IT/Ops!"
end

get '/changepw' do
	@user=authenticate()
	unless @user
		redirect '/unauthenticated'
	end
	haml :changepw
end

post '/changepw' do
	@user=authenticate()
	unless @user
		redirect '/unauthenticated'
	end
	currentpass	= params["current"]
	newpass		= params["new"]
	newpass_sanity	= params["new_sanity"]
	buffer		= ""
	if newpass != newpass_sanity
		haml :passwords_do_not_match
	elsif newpass == currentpass
		haml :password_did_not_change
	else
		require 'pty'    
		require 'expect'

		@error = ""

		# spawn a child process (fork)
		PTY.spawn("/usr/bin/kpasswd #{@user}") do |output, input, pid|
		   input.sync = true

		   #set the expect verbosity flag to false or you will get output from expect
   		   expect_verbose = false

   		   #expect the username prompt and return the username
   		   output.expect(/Password for #{@user}/) do
      			input.puts(currentpass)
   		   end

   		   output.expect('Enter new password: ') do
     			input.puts(newpass)
   		   end
   		   
		   output.expect('Enter it again: ') do
     			input.puts(newpass)
   		   end

       		   @error=output.read
		
		end
		haml :kpasswd_results
	end
end	
