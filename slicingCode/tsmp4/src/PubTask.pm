package PubTask;

use strict;
use warnings;

use Smart::Comments;

$|++;
#use Net::RabbitFoot;
use version;
use base qw(Exporter);

our $VERSION = v0.1;
our @EXPORT  = qw(publish_task);

sub publish_task {
    my $msg = shift;
    print("Got message to send [$msg]\n");
    my $exchange = 'mogilefs';
    my $type = 'fanout';
    my $conn = connect_rabbitmq();
    my $channel = $conn->open_channel();

    $channel->declare_exchange(
        exchange => $exchange,
        type => $type,
    );


    $channel->publish(
        exchange => $exchange,
        routing_key => '',
        body => $msg,
    );
    print " [x] sent $msg\n";

    $conn->close();
}

sub connect_rabbitmq {
    my $ip = '192.168.1.222';

    my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host => $ip,
        port => 5672,
        user => 'guest',
        pass => 'guest',
        vhost => '/',
    );

## $conn
    return $conn;
}

1;
