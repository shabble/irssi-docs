__END__

=head1 NAME

Irssi.pm

=head1 DESCRIPTION

L<Irssi|http://irssi.org> is a console based fullscreen IRC client.  It is
written in the C programming language, and can be modified through both
I<Modules> -- dynamically loadable compiled libraries -- and I<Scripts>, written
in L<Perl|http://perl.org>.

Modules are not covered in this documentation, other than to note that Perl
scripting support itself may be compiled as a module rather than built directly
into Irssi.  The C</LOAD> command can be used from within Irssi to check if Perl
support is available. If not, refer to the F<INSTALL> file for how to recompile
irssi.

The C<Irssi> package is the basis of Perl scripting in Irssi. It does not export any
functions, and requires that all function-calls be fully qualified with the
C<Irssi::I<cmd>> prefix.

=head1 CLASSES

This documentation has been split into a number of pages, each documenting a
particular class or pseudo-class.  The following list contains all of these
additional pages.

=over 4

=item L<Irssi::Ban>

=item L<Irssi::Chatnet>

=item L<Irssi::Chatnet>

=item L<Irssi::Client>

=item L<Irssi::Command>

=item L<Irssi::Dcc>

=item L<Irssi::Ignore>

=item L<Irssi::Log>

=item L<Irssi::Logitem>

=item L<Irssi::Nick>

=item L<Irssi::Notifylist>

=item L<Irssi::Process>

=item L<Irssi::Query>

=item L<Irssi::Rawlog>

=item L<Irssi::Reconnect>

=item L<Irssi::Script>

=item L<Irssi::Server>

=item L<Irssi::Theme>

=item L<Irssi::Window>

=item L<Irssi::Windowitem>

=back

=head1 METHODS

=head2 Accessors

=head3 active_win

C<my $win = Irssi::active_win();>

returns the currently active L<Irssi::Window>

=head3 active_server

C<my $server = Irssi::active_server();>

returns the currently active L<Irssi::Server> in active window.

=head3 windows

returns a list of all L<windows|Irssi::Window>.

=head3 servers

returns a list of all L<servers|Irssi::Server>.

=head3 reconnects

returns a list of all L<server reconnections|Irssi::Reconnect>.

=head3 channels

returns a list of all L<channels|Irssi::Channel>.

=head3 queries

returns a list of all L<queries|Irssi::Query>.

=head3 commands

returns a list of all L<commands|Irssi::Command>.

=head3 logs

returns a list of all L<log files|Irssi::Log>.

=head3 ignores

returns a list of all L<ignores|Irssi::Ignore>.

=head3 dccs

returns a list of all L<DCC connections|Irssi::Dcc>

=head2 Signals

See also L<Signals>

Irssi is pretty much based on sending and handling different signals.
Like when you receive a message from server, say:

C<:nick!user@there.org PRIVMSG you :blahblah>

Irssi will first send a signal:

C<"server incoming", SERVER_REC, "nick!user@there PRIVMSG ...">

You probably don't want to use this signal. Default handler for this
signal interprets the header and sends a signal:

C<"server event", Irssi::Server, "PRIVMSG ...", "nick", "user@there.org">

You probably don't want to use this either, since this signal's default
handler parses the event string and sends a signal:

C<"event privmsg", Irssi::Server, "you :blahblah", "nick", "user@there.org">

You can at any point grab the signal, do whatever you want to do with
it and optionally stop it from going any further by calling
L<Irssi::signal_stop|Irssi/signal_stop>

For example:

    sub event_privmsg {
        # $data = "nick/#channel :text"
        my ($server, $data, $nick, $address) = @_;
        my ($target, $text) = split(/ :/, $data, 2);

        Irssi::signal_stop() if ($text =~ /free.*porn/ || $nick =~ /idiot/);
    }

    Irssi::signal_add("event privmsg", "event_privmsg");

This will hide all public or private messages that match the regexp
C<"free.*porn"> or the sender's nick contain the word "idiot". Yes, you
could use /IGNORE instead for both of these C<:)>

You can also use L<Irssi::signal_add_last|/signal_add_last> if you wish to let the
Irssi's internal functions be run before yours.

A list of signals that irssi sends can be found in the L<Signals> documentation.




=head3 Handling Signals

=head4 C<signal_add $sig_name, $func>

Bind C<$sig_name> to function C<$func>. The C<$func> argument may be either
a string containing the name of a function to call, or a coderef.

For example:

    Irssi::signal_add("default command", sub { ... });

    Irssi::signal_add("default command", "my_function");

    Irssi::signal_add("default command", \&my_function);

In all cases, the specified function will be passed arguments in C<@_> as specified
in L<Signals>.

=head4 C<signal_add_first $sig_name, $func>

Bind C<$sig_name> to function C<$func>. Call C<$func> as soon as possible when
the signal is raised.

=head4 C<signal_add_last $sig_name, $func>

Bind C<$sig_name> to function C<$func>. Call C<$func> as late as possible (after
all other signal handlers).

=head4 C<signal_remove $sig_name, $func>

Unbind C<$sig_name> from function C<$func>.
B<TODO: Can you unbind a signal from a C<sub { ...}> coderef? What happens?>


=head3 Controlling Signal Propagation

=head4 C<signal_emit $sig_name, @params>

Send a signal of type C<$sig_name>. Up to 6 parameters can be passed in C<@params>.

=head4 C<signal_continue @params>

Propagate a currently emitted signal, but with different parameters.  This only
needs to be called if you wish to change them, otherwise all subsequent handlers
will be invoked as normal.

B<Should only be called from within a signal handler>

=head4 C<signal_stop>

Stop the signal that's currently being emitted, no other handlers after this one will
be called.

=head4 C<signal_stop_by_name $sig_name>

Stop the signal with name C<$sig_name> that is currently being emitted.

=head3 Registering New Signals

=head4 C<signal_register $hashref>

Register parameter types for one or more signals.  C<$hashref> must map one or
more signal names to references to arrays containing 0 to 6 type names. Some
recognized type names include int for integers, intptr for references to
integers and string for strings. For all standard signals see
F<src/perl/perl-signals-list.h> in the source code (this is generated by
F<src/perl/get-signals.pl>).

For example:

    my $signal_config_hash = { "new signal" => [ qw/string string integer/ ] };
    Irssi::signal_register($signal_config_hash);

Any signals that were already registered are unaffected.

B<Signals are not persistent.>  Once registered, a signal cannot be unregistered without
restarting Irssi. B<TODO: True?>, including modifying the type signature.

Registration is required to get any parameters to signals written in
Perl and to emit and continue signals from Perl.

B<TODO: What are the complete list of recognised types?>




=head2 Commands

See also L<Irssi::Command>

=head3 Registering Commands

=head4 C<command_bind $cmd, $func, $category

Bind a command string C<$cmd> to call function C<$func>. C<$func> can be
either a string or coderef. C<$category> is an optional string specifying
the category to display the command in when C</HELP> is used.

=head4 C<command_runsub $cmd, $data, $server, $item>

Run subcommands for `cmd'. First word in `data' is parsed as
subcommand. `server' is L<Irssi::Server> record for current
L<Irssi::Windowitem> `item'.

Call command_runsub in handler function for `cmd' and bind
with command_bind("`cmd' `subcmd'", subcmdfunc[, category]);

B<TODO: example here>

=head4 C<command_unbind $cmd, $func>

Unbind command C<$cmd> from function C<$func>.

=head3 Invoking Commands

=head4 C<command $string>

Run the command specified in C<$string> in the currently active context.

B<TODO: passing args in C<@_> vs concatenating into the command string?>

See also L<Irssi::Server/command $string>

=head3 Parsing Command Arguments

=head4 C<command_set_options(cmd, data)>

Set options for command `cmd' to `data'. `data' is a string of
space separated words which specify the options. Each word can be
optionally prefixed with one of the following character:

=over

=item  '-': optional argument

=item   '+': argument required

=item   '@': optional numeric argument

=back

=head4 C<command_parse_options(cmd, data)>

Parse options for command `cmd' in `data'. It returns a reference to
an hash table with the options and a string with the remaining part
of `data'. On error it returns the undefined value.



=head2 Settings


=head3 Creating New Settings

=head4 C<settings_add_str(section, key, def)>

=head4 C<settings_add_int(section, key, def)>

=head4 C<settings_add_bool(section, key, def)>

=head4 C<settings_add_time(section, key, def)>

=head4 C<settings_add_level(section, key, def)>

=head4 C<settings_add_size(section, key, def)>


=head3 Retrieving Settings

=head4 C<settings_get_str($key)>

=head4 C<settings_get_int($key)>

=head4 C<settings_get_bool($key)>

=head4 C<settings_get_time($key)>

=head4 C<settings_get_level($key)>

=head4 C<settings_get_size($key)>

=head3 Modifying Settings

Set value for setting.

B<If you change the settings of another module/script with one of these, you
must emit a C<"setup changed"> signal afterwards.>

=head4 C<settings_set_str(key, value)>

=head4 C<settings_set_int(key, value)>

=head4 C<settings_set_bool(key, value)>

=head4 C<settings_set_time(key, value)>

=head4 C<settings_set_level(key, value)>

=head4 C<settings_set_size(key, value)>

=head4 C<settings_remove(key)>

Remove a setting.


=head2 IO and Process Management

timeout_add(msecs, func, data)
  Call `func' every `msecs' milliseconds (1000 = 1 second) with
  parameter `data'. Returns tag which can be used to stop the timeout.

timeout_add_once(msecs, func, data);
  Call `func' once after `msecs' milliseconds (1000 = 1 second)
  with parameter `data'. Returns tag which can be used to stop the timeout.

timeout_remove(tag)
  Remove timeout with tag.

input_add(source, condition, func, data)
  Call `func' with parameter `data' when specified IO happens.
  `source' is the file handle that is being listened. `condition' can
  be INPUT_READ, INPUT_WRITE or both. Returns tag which can be used to
  remove the listener.

input_remove(tag)
  Remove listener with tag.

pidwait_add(pid)
  Adds `pid' to the list of processes to wait for. The pid must identify
  a child process of the irssi process. When the process terminates, a
  "pidwait" signal will be sent with the pid and the status from
  waitpid(). This is useful to avoid zombies if your script forks.

pidwait_remove(pid)
  Removes `pid' from the list of processes to wait for. Terminated
  processes are removed automatically, so it is usually not necessary
  to call this function.



=head2 Message Levels

level2bits(level)
  Level string -> number

bits2level(bits)
  Level number -> string

combine_level(level, str)
  Combine level number to level string ("+level -level").
  Return new level number.


=head2 Themes

See also L<Irssi::Theme>

You can have user configurable texts in scripts that work just like
irssi's internal texts that can be changed in themes.

First you'll have to register the formats:


Irssi::theme_register([
  'format_name', '{hilight my perl format!}',
  'format2', 'testing.. nick = $0, channel = $1'
]);

Printing happens with one of the functions:

printformat(level, format, ...)
Window::printformat(level, format, ...)
Server::printformat(target, level, format, ...)
Windowitem::printformat(level, format, ...)

For example:

  $channel->printformat(MSGLEVEL_CRAP, 'format2',
		        'nick', $channel->{name});


=head2 DCC

See also L<Irssi::Dcc>

Dcc
dcc_find_item(type, nick, arg)
  Find DCC connection.

Dcc
dcc_find_by_port(nick, port)
  Find DCC connection by port.


=head2 Channels

Channel
channel_find(channel)
  Find channel from any server.

=head2 Ignores


ignore_add_rec(ignore)
  Add ignore record.

ignore_update_rec(ignore)
  Update ignore record in configuration

ignore_check(nick, host, channel, text, level)

=head2 Logging


Log
log_create_rec(fname, level)
  Create log file.


Log
log_find(fname)
  Find log with file name.

=head2 Raw Logging

Rawlog rawlog_create()
  Create a new rawlog.

rawlog_set_size(lines)
  Set the default rawlog size for new rawlogs.

=head2 Chat-Nets

chatnet_find(name)
  Find chat network with name.


=head1 COPYRIGHT

All the content of this site is copyright © 2000-2010 The Irssi project.

Formatting to POD and linking by Tom Feist
 L<shabble+irssi@metavore.org|mailto:shabble+irssi@metavore.org>
