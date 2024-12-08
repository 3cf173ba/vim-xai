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

xai_complete.pl - A script to interact with an AI completion service from within Vim

=head1 SYNOPSIS

    perl xai_complete.pl

=head1 DESCRIPTION

This script is designed to be used within Vim to send text selections to an external AI service for completion or processing. It uses HTTP requests to communicate with the service, handles streaming responses, and updates the Vim buffer with the received content.

=head1 PREREQUISITES

=over 4

=item * LWP::UserAgent

=item * HTTP::Request

=item * JSON

=item * utf8

=back

=head1 FUNCTIONS

=over 4

=item B<main()>

The main function orchestrates the script's operation:

=over 4

=item * Evaluates Vim variables for configuration.

=item * Prepares the JSON payload for the API request.

=item * Sends a POST request to the AI service.

=item * Handles the response, either streaming or immediate.

=back

=item B<do_msg($chunk)>

Handles streaming data from the API:

=over 4

=item * Collects chunks of data into a buffer.

=item * Processes complete messages from the buffer.

=item * Updates the Vim buffer with new content from the AI.

=back

=back

=head2 Configuration Variables

The script uses several Vim variables for configuration:

=over 4

=item * C<g:vim_xai_complete_default_url> - URL for the AI service.

=item * C<g:vim_xai_complete_default> - Default JSON payload for the request.

=item * C<g:vim_xai_token> - Authentication token for the API.

=item * C<g:vim_xai_user_agent> - User agent string for HTTP requests.

=item * C<s:vim_xai_args> - Additional arguments for the AI request.

=item * C<l:selection> - The text selection from Vim to be processed.

=back

=head2 HTTP Request Setup

=over 4

=item * Uses LWP::UserAgent for making HTTP requests.

=item * Sets up headers including Content-Type and Authorization.

=item * Configures SSL options to bypass hostname verification.

=back

=head2 Response Handling

=over 4

=item * If the response is successful, it prints a success message and processes the content.

=item * If there's an error, it prints the status line of the failed request.

=back

=head1 NOTES

=over 4

=item * The script assumes UTF-8 encoding for all text operations.

=item * Streaming responses are handled by appending to the Vim buffer in real-time.

=item * Error handling is minimal; the script dies on failure to evaluate Vim variables.

=back

=head1 AUTHOR

Albert J. Mendes

=head1 SEE ALSO

L<Vim>, L<LWP::UserAgent>, L<HTTP::Request>, L<JSON>

=cut
