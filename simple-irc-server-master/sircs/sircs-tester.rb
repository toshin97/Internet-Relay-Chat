#! /usr/bin/env ruby
#
# CMPU-375 Simple IRC server tester
# Team: Junrui, Tahsin, Shihan 
# This script sends a sequence of commands to our IRC server and inspects
# the replies to see if it is behaving correctly.
#
#
#

require 'socket'

$SERVER = "127.0.0.1"
$PORT = 9999   

if ARGV.size == 0
    puts "Usage: ./sircs-tester.rb [servIpAddr] [servPort]"
    puts "Using servIpAddr: #{$SERVER}, servPort: #{$PORT}"
elsif ARGV.size >= 1
    $SERVER = ARGV[0].to_s()
end

if ARGV.size >= 2
begin
    $PORT = Integer(ARGV[1])
rescue
    puts "The port number must be an integer!"
    exit
end
end

puts "Server address - " + $SERVER + ":" + $PORT.to_s()

class IRC

    def initialize(server, port, nick, channel)
        @server = server
        @port = port
        @nick = nick
        @channel = channel
    end

    def recv_data_from_server (timeout)
        pending_event = Time.now.to_i
        received_data = Array.new
        k = 0
        flag = 0
        while flag == 0
            ## check for timeout
            time_elapsed = Time.now.to_i - pending_event
            if (time_elapsed > timeout)
                flag = 1
            end
            ready = select([@irc], nil, nil, 0.0001)
            next if !ready
            for s in ready[0]
                if s == @irc then
                    next if @irc.eof
                    s = @irc.gets
                    received_data[k] = s
                    k= k + 1
                end
            end
        end
        return received_data
    end

    def test_silence(timeout)
        data=recv_data_from_server(timeout)
        if (data.size > 0)
            return false
        else
            return true
        end
    end

    def send(s)
        # Send a message to the irc server and print it to the screen
        puts "--> #{s}"
        @irc.send "#{s}\n", 0
    end

    def connect()
        # Connect to the IRC server
        @irc = TCPSocket.open(@server, @port)
    end

    def disconnect()
        @irc.close
    end

    def send_nick(s)
        send("NICK #{s}")
    end

    def send_user(s)
        send("USER #{s}")
    end

    def get_motd
        data = recv_data_from_server(1)
        ## CHECK data here

        if(data[0] =~ /^:[^ ]+ *375 *sherlock *:- *[^ ]+ *Message of the day - *.\n/)
            puts "\tRPL_MOTDSTART 375 correct"
        else
            puts "hello"
            puts data[0]
            puts "\tRPL_MOTDSTART 375 incorrect"
            return false
        end

        k = 1
        while ( k < data.size-1)

            if(data[k] =~ /:[^ ]+ *372 *sherlock *:- *.*/)
                puts "\tRPL_MOTD 372 correct"
            else
                puts "\tRPL_MOTD 372 incorrect"
                return false
            end
            k = k + 1
        end

        if(data[data.size-1] =~ /:[^ ]+ *376 *sherlock *:End of \/MOTD command/)
            puts "\tRPL_ENDOFMOTD 376 correct"
        else
            puts "\tRPL_ENDOFMOTD 376 incorrect"
            return false
        end

        return true
    end

    def send_privmsg(s1, s2)
	send("PRIVMSG #{s1} :#{s2}")
    end

    def raw_join_channel(joiner, channel)
        send("JOIN #{channel}")
        ignore_reply()
    end

    def join_channel(joiner, channel)
        send("JOIN #{channel}")

        data = recv_data_from_server(1);
        if(data[0] =~ /^:#{joiner}.*JOIN *#{channel}/)
            puts "\tJOIN echoed back"
        else
            puts "\tJOIN was not echoed back to the client"
            return false
        end

        if(data[1] =~ /^:[^ ]+ *353 *#{joiner} *= *#{channel} *:.*#{joiner}/)
            puts "\tRPL_NAMREPLY 353 correct"
        else
            puts "\tRPL_NAMREPLY 353 incorrect"
            return false
        end

        if(data[2] =~ /^:[^ ]+ *366 *#{joiner} *#{channel} *:End of \/NAMES list/)
            puts "\tRPL_ENDOFNAMES 366 correct"
        else
            puts "\tRPL_ENDOFNAMES 366 incorrect"
            return false
        end

        return true
    end

    def who(s)
        send("WHO #{s}")

        data = recv_data_from_server(1);

        if(data[0] =~ /^:[^ ]+ *352 *sherlock *#{s} *myUsername *[^ ]+ *[^ ]+ *rui *H *:0 */)
            puts "\tRPL_WHOREPLY 352 correct"
        else
            puts data
            puts "\tRPL_WHOREPLY 352 incorrect"
            return false
        end

        if(data[1] =~ /^:[^ ]+ *315 *sherlock *#{s} *:End of \/WHO list/)
            puts "\tRPL_ENDOFWHO 315 correct"
        else
            puts "\tRPL_ENDOFWHO 315 incorrect"
            return false
        end
        return true
    end

    def list
	send("LIST")

        data = recv_data_from_server(1);
        if(data[0] =~ /^:[^ ]+ *321 *sherlock *Channel *:Users Name/)
            puts "\tRPL_LISTSTART 321 correct"
        else
            puts "\tRPL_LISTSTART 321 incorrect"
            return false
        end

        if(data[1] =~ /^:[^ ]+ *322 *sherlock *#linux.*1/)
            puts "\tRPL_LIST 322 correct"
        else
            puts "\tRPL_LIST 322 incorrect"
            return false
        end

        if(data[2] =~ /^:[^ ]+ *323 *sherlock *:End of \/LIST/)
            puts "\tRPL_LISTEND 323 correct"
        else
            puts "\tRPL_LISTEND 323 incorrect"
            return false
        end

        return true
    end

    def checkmsg(from, to, msg)
	reply_matches(/^:#{from} *PRIVMSG *#{to} *:#{msg}/, "PRIVMSG")
    end

    def check2msg(from, to1, to2, msg)
        data = recv_data_from_server(1);
        if((data[0] =~ /^:#{from} *PRIVMSG *#{to1} *:#{msg}/ && data[1] =~ /^:#{from} *PRIVMSG *#{to2} *:#{msg}/) ||
           (data[1] =~ /^:#{from} *PRIVMSG *#{to1} *:#{msg}/ && data[0] =~ /^:#{from} *PRIVMSG *#{to2} *:#{msg}/))
            puts "\tPRIVMSG to #{to1} and #{to2} correct"
            return true
        else
            puts "\tPRIVMSG to #{to1} and #{to2} incorrect"
            return false
        end
    end

    def check_echojoin(from, channel)
	reply_matches(/^:#{from}.*JOIN *#{channel}/,
			    "Test if first client got join echo")
    end

    def part_channel(parter, channel)
        send("PART #{channel}")
	reply_matches(/^:#{parter}![^ ]+@[^ ]+ *QUIT *:/)

    end

    def check_part(parter, channel)
	reply_matches(/^:#{parter}![^ ]+@[^ ]+ *QUIT *:/)
    end

    def ignore_reply
        recv_data_from_server(1)
    end

    def reply_matches(rexp, explanation = nil)
	data = recv_data_from_server(1)
	if (rexp =~ data[0])
	    puts "\t #{explanation} correct" if explanation
	    return true
	else
	    puts "\t #{explanation} incorrect: #{data[0]}" if explanation
	    return false
	end
    end

end


##
# The main program.  Tests are listed below this point.  All tests
# should call the "result" function to report if they pass or fail.
##

$total_points = 0

def test_name(n)
    puts "////// #{n} \\\\\\\\\\\\"
    return n
end

def result(n, passed_exp, failed_exp, passed, points)
    explanation = nil
    if (passed)
	print "(+) #{n} passed"
	$total_points += points
	explanation = passed_exp
    else
	print "(-) #{n} failed"
	explanation = failed_exp
    end

    if (explanation)
	puts ": #{explanation}"
    else
	puts ""
    end
end

def eval_test(n, passed_exp, failed_exp, passed, points = 1)
    result(n, passed_exp, failed_exp, passed, points)
    exit(0) if !passed
end

irc = IRC.new($SERVER, $PORT, '', '')
irc.connect()
begin

########## TEST NICK COMMAND ##########################
# The RFC states that there is no response to a NICK command,
# so we test for this.
    tn = test_name("NICK")
    irc.send_nick("sherlock")
    puts "<-- Testing for silence (5 seconds)..."

    eval_test(tn, nil, nil, irc.test_silence(5))


############## TEST USER COMMAND ##################
# The RFC states that there is no response on a USER,
# so we disconnect first (otherwise the full registration
# of NICK+USER would give us an MOTD), then check
# for silence
    tn = test_name("USER")

    puts "Disconnecting and reconnecting to IRC server\n"
    irc.disconnect()
    irc.connect()

    irc.send_user("myUsername myHostname myServername :My real name")
    puts "<-- Testing for silence (5 seconds)..."

    eval_test(tn, nil, "should not return a response on its own",
	      irc.test_silence(1))

############# TEST FOR REGISTRATION ##############
# A NICK+USER is a registration that triggers the
# MOTD.  This test sends a nickname to complete the registration,
# and then checks for the MOTD.
tn = test_name("Registration")
irc.send_nick("sherlock")
puts "<-- Listening for MOTD...";

eval_test(tn, nil, nil, irc.get_motd())

############## TEST JOINING ####################
# We join a channel and make sure the client gets
# his join echoed back (which comes first), then
# gets a names list.
    tn = test_name("JOIN")
    eval_test(tn, nil, nil,
        irc.join_channel("sherlock", "#linux"))

############## WHO ####################
# Who should list everyone in a channel
# or everyone on the server.  We are only
# checking WHO <channel>.
# The response should follow the RFC.
    tn = test_name("WHO")
    eval_test(tn, nil, nil, irc.who("#linux"))

############## LIST ####################
# LIST is used to check all the channels on a server.
# The response should include #linux and its format should follow the RFC.
    # tn = test_name("LIST")
    # eval_test(tn, nil, nil, irc.list())

############## PRIVMSG ###################
# Connect a second client that sends a message to the original client.
# Test that the original client receives the message.
tn = test_name("PRIVMSG")
irc2 = IRC.new($SERVER, $PORT, '', '')
irc2.connect()
irc2.send_nick("john")
irc2.send_user("myUsername2 myHostname2 myServername2 :My real name 2")
msg = "2B | !2B, that is the question?"
irc2.send_privmsg("sherlock", msg)
eval_test(tn, nil, nil, irc2.checkmsg("john", "sherlock", msg))

# Connect third client who sends msg to 2nd client, 
# test if second client receives msg
tn = test_name("PRIVMSG2")
irc3 = IRC.new($SERVER, $PORT, '', '')
irc3.connect()
irc3.send_nick("irene")
irc3.send_user("myUsername3 myHostname3 myServername3 :My real name 3")
msg = "What is the purpose of life?"
irc3.send_privmsg("john", msg)
eval_test(tn, nil, nil, irc3.checkmsg("irene", "john", msg))

############## ECHO JOIN ###################
# When another client joins a channel, all clients
# in that channel should get :newuser JOIN #channel
    tn = test_name("ECHO ON JOIN")
    # "raw" means no testing of responses done
    irc2.raw_join_channel("john", "#linux")
    irc2.ignore_reply()
    eval_test(tn, nil, nil,
        irc2.join_channel("john", "#linux"))
    eval_test(tn, nil, nil, irc2.check_echojoin("john", "#linux"))



############## MULTI-TARGET PRIVMSG ###################
# A client should be able to send a single message to
# multiple targets, with ',' as a delimiter.
# We use client2 to send a message to sherlock and #linux.
# Both should receive the message.
    tn = test_name("MULTI-TARGET PRIVMSG")
    msg = "success is 1 % inspiration and 99 % perspiration"
    irc2.send_privmsg("sherlock, #linux", msg)
    eval_test(tn, nil, nil, irc.checkmsg("john", "sherlock", "#linux", msg))
    irc2.ignore_reply()

    # Use client3 to join channel #linux , send msg to all clients
    tn = test_name("ECHO ON IRENE JOINING LINUX")
    irc3.raw_join_channel("irene", "#linux")
    irc3.ignore_reply()
    eval_test(tn, nil, nil,
        irc3.join_channel("irene", "#linux"))
    eval_test(tn, nil, nil, irc3.check_echojoin("irene", "#linux"))

    tn = test_name("MULTI-TARGET PRIVMSG2")
    msg = "Imagination is more powerful than knowlegdge"
    irc3.send_privmsg("#linux", msg)
    eval_test(tn, nil, nil, irc3.checkmsg("irene", "#linux", msg))
    irc3.ignore_reply()


    # create client 4, join channel #linux 
    tn = test_name("ECHO ON WATSON JOINING LINUX")
    irc4 = IRC.new($SERVER, $PORT, '', '')
    irc4.connect()
    irc4.send_nick("watson")
    irc4.send_user("myUsername4 myHostname4 myServername4 :My real name 4")
    irc4.raw_join_channel("watson", "#linux")
    irc4.ignore_reply()
    eval_test(tn, nil, nil,
        irc4.join_channel("watson", "#linux"))
    eval_test(tn, nil, nil, irc4.check_echojoin("watson", "#linux"))

    #send msg to all other clients on channel, check if received
    tn = test_name("MULTI-TARGET PRIVMSG3")
    msg = "It is not okay. It is what it is."
    irc4.send_privmsg("sherlock", "john", "irene", "#linux", msg)
    eval_test(tn, nil, nil, irc4.checkmsg("watson", "sherlock", "john", "irene", 
                                            "#linux", msg))
    irc4.ignore_reply()



############## PART ###################
# When a client parts a channel, a QUIT message
# is sent to all clients in the channel, including
# the client that is parting.
    tn = test_name("PART")
    eval_test("PART echo to self", nil, nil,
	      irc2.part_channel("john", "#linux"),
	      0) # note that this is a zero-point test!

    eval_test("PART echo to other clients", nil, nil,
	      irc.check_part("john", "#linux"))


# Client 3 disconnect, check if it's automatically parted
    tn = test_name("PART2")


#----------------------
# More TESTS continued
#----------------------

#client 2 (John) joining new channel #turing
tn = test_name("ECHO ON JOINING NEW CHANNEL")
irc2.raw_join_channel("john", "#turing") 
irc2.ignore_reply()

#part current channel #linux, send echo to self
eval_test("PART echo to self", nil, nil,
      irc2.part_channel("john", "#linux"),
      0) 
#send echo to all clients on #linux when parting
eval_test("PART echo to other clients", nil, nil,
      irc2.check_part("john", "#linux"))

#client gets his join echoed back (which comes first), then
# gets a names list
eval_test(tn, nil, nil,
    irc2.join_channel("john", "#turing"))
#send echo to clients on #turing 
eval_test(tn, nil, nil, irc2.check_echojoin("john", "#turing"))



#client 5(Adler) joins new channel (for first time) #turing 
irc5 = IRC.new($SERVER, $PORT, '', '')
irc5.connect()
irc5.send_nick("adler")
irc5.send_user("myUsername5 myHostname5 myServername5 :My real name 5")

tn = test_name("ECHO ON JOIN3")
irc5.raw_join_channel("adler", "#turing") #joining new channel #turing
irc5.ignore_reply()
eval_test(tn, nil, nil,
    irc5.join_channel("adler", "#turing"))
eval_test(tn, nil, nil, irc5.check_echojoin("adler", "#turing"))

#check message from Adler to John
msg = "Are you getting my msg, John"
irc5.send_privmsg("john", msg)
eval_test(tn, nil, nil, irc5.checkmsg("adler", "john", msg))

##check reply from John
msg = "Yes I got you msg, Adler"
irc2.send_privmsg("adler", msg)
eval_test(tn, nil, nil, irc2.checkmsg("john", "adler", msg))

#Adler sends msg to #turing
tn = test_name("MULTI-TARGET MSG ON JOINING")
msg = "Hey y'all on channel Turing! Adler here!"
irc5.send_privmsg("#turing", msg)
eval_test(tn, nil, nil, irc5.checkmsg("adler", "#turing", msg))
irc5.ignore_reply()


# Things to test:
#  - Multiple clients in a channel
#  - Abnormal messages of various sorts
#  - Clients that misbehave/disconnect/etc.
#  - Lots and lots of clients
#  - Lots and lots of channel switching
#  - etc.
##


rescue Interrupt
rescue Exception => detail
    puts detail.message()
    print detail.backtrace.join("\n")
ensure
    irc.disconnect()
    puts "Your score: #{$total_points} / 10"
    puts ""
    puts "Good luck with the rest of the project!"
end
