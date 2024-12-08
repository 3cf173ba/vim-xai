use LWP::UserAgent;
use HTTP::Request;
use JSON;
use utf8;
use open ':std', ':encoding(UTF-8)';

$chunk_buffer = '';
$collect_messages = '';

main();

sub main {
    @evals = (
        "l:selection",
        "s:vim_xai_args",
        "g:vim_xai_complete_default_url",
        "g:vim_xai_complete_default",
        "g:vim_xai_token",
        "g:vim_xai_user_agent"
    );

    for (@evals) {
        $var = (split /:/, $_, 2)[1];
        ($success, ${$var}) = VIM::Eval($_);

        die "Could not evaluate vim variable $_" unless $success;
    }

    $lines = $curbuf->Count();
    # Append newlines.
    $curbuf->Append($lines, ("", "", ""));

    $xai_xd_obj = decode_json "$vim_xai_complete_default";
    $xai_xd_obj->{stream} = ($xai_xd_obj->{stream} == 1) ? \1 : \0;
    push @{$xai_xd_obj->{messages}}, {
        "role"      => "user",
        "content"   => $vim_xai_args . "\n\n" . $selection
    };

    $json_string = encode_json $xai_xd_obj;

    $headers = [
        'Content-Type'      => 'application/json',
        'Authorization'     => 'Bearer ' . $vim_xai_token
    ];

    $ua = LWP::UserAgent->new(
        protocols_allowed   => ['https'],
        agent               => $vim_xai_user_agent,
        default_header      => $headers,
        ssl_opts            => {
            "verify_hostname"       => 0
        },
    );

    $req = HTTP::Request->new(POST => $vim_xai_complete_default_url,
        $headers,
        $json_string
    );

    $response = $ua->request($req, \&do_msg);

    if ($response->is_success) {
        print "\nRequest succeeded.\n";
    } else {
        print "Request failed: ", $response->status_line, "\n";
    }
}

sub do_msg {
    # Enable autoflush to ensure immediate output
    local $| = 1;

    $chunk = shift;
    $chunk_buffer .= $chunk;

    # Return early if we don't have a complete message
    return unless $chunk_buffer =~ /\n\n$/;

    @messages = split /\n/, $chunk_buffer;
    $chunk_buffer = '';

    for (@messages) {
        chomp;
        next if $_ eq '';

        ($d, $json) = split /: /, $_, 2;
        return if $json eq '[DONE]';

        $json_decoded = decode_json $json;
        next unless defined $json_decoded->{choices}[0]{delta}{content};
        return if $json_decoded->{choices}[0]->{finish_reason};

        $collect_messages .= $json_decoded->{choices}[0]->{delta}->{content};

        # Update Vim buffer
        VIM::DoCommand("normal! G");
        VIM::DoCommand("redraw");

        $lines = $curbuf->Count();

        $curbuf->Set($lines, $collect_messages);

        VIM::DoCommand('silent! %s/\%x00/\r/g');
        $lines = $curbuf->Count();
        $collect_messages = $curbuf->Get($lines);
    }
}

__END__


=pod

=head1 NAME

xai_complete - A Perl script for interacting with an AI completion service

=head1 SYNOPSIS

    use LWP::UserAgent;
    use HTTP::Request;
    use JSON;
    use utf8;
    use open ':std', ':encoding(UTF-8)';

    main();

=head1 DESCRIPTION

This script is designed to interact with an AI completion service, likely for use within a Vim plugin or similar text editor environment. It sends a request to an AI service with user-defined parameters and processes the streaming response to update the Vim buffer in real-time.

=head1 FUNCTIONS

=over 4

=item B<main()>

The main function orchestrates the script's operation:

=over 4

=item * Evaluates Vim variables for configuration.

=item * Prepares and sends an HTTP POST request to the AI service.

=item * Handles the response, either streaming or non-streaming, and updates the Vim buffer accordingly.

=back

=item B<do_msg($chunk)>

Processes chunks of the streaming response:

=over 4

=item * Accumulates chunks until a complete message is received.

=item * Decodes JSON from the message chunks.

=item * Updates the Vim buffer with the AI's response content.

=item * Ensures immediate output by setting autoflush.

=back

=back

=head1 VARIABLES

=over 4

=item C<$chunk_buffer>

Stores incomplete chunks of the streaming response.

=item C<$collect_messages>

Accumulates the content of the AI's response for display.

=item C<@evals>

An array of Vim variables to evaluate for configuration.

=item C<$xai_xd_obj>

A JSON object representing the request to the AI service.

=item C<$json_string>

The JSON encoded string of the request object.

=item C<$headers>

HTTP headers for the request, including authentication.

=item C<$ua>

An instance of LWP::UserAgent for making HTTP requests.

=item C<$req>

The HTTP request object.

=item C<$response>

The HTTP response object from the AI service.

=back

=head1 DEPENDENCIES

=over 4

=item * LWP::UserAgent

=item * HTTP::Request

=item * JSON

=item * utf8

=item * open

=back

=head1 AUTHOR

Albert J. Mendes <tray.mendes@gmail.com>

=head1 SEE ALSO

L<Vim>, L<Perl>, L<JSON>, L<LWP::UserAgent>

=cut
