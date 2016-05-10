#!/usr/bin/perl
 
use strict;
use warnings;
use Net::DBus;
use Net::DBus::Service;
use Net::DBus::Reactor;
use Data::UUID;
use DateTime::Format::XSD;

package TrisvcEchoModule;
use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(com.trisvc.modules.BaseObject);
 
# Constructor
sub new
{
   my $class = shift;
   my $service = shift;
   my $self = $class->SUPER::new($service, "/com/trisvc/modules/Echo/default");
   bless $self, $class;
   return $self;
}

# Module functionality
sub send
{
   my ($self, $message)=@_;

   my $dt    = DateTime->now();
   my $dts   = DateTime::Format::XSD->format_datetime($dt);

   (my $callerID)  = $message =~ /<callerID>(.*)<\/callerID>/;
   (my $messageID) = $message =~ /<messageID>(.*)<\/messageID>/;
   (my $text)      = $message =~ /<value>(.*)<\/value>/;

   my $response = 
      "<response>
          <type>InvokeResponse</type>
          <time>$dts</time>
          <callerID>$callerID</callerID> 
          <messageID>$messageID</messageID>
          <invokeResponse>
              <message>$text</message>
          </invokeResponse>
          <listener>Perl</listener>
          <success>true</success>
      </response>";

   return $response;
}

# Declare method implementation
dbus_method("send", ["string"], ["string"]);
 
package main;

# Generate register message
sub genRegisterMessage{

   my $ug    = Data::UUID->new;
   my $uuid  = $ug->to_string($ug->create());
   my $dt    = DateTime->now();
   my $dts   = DateTime::Format::XSD->format_datetime($dt);

   my $registerMessage=
      "<message>
          <type>RegisterMessage</type>
          <time>$dts</time>
          <callerID>Perl</callerID>
          <messageID>$uuid</messageID>
          <registerMessage>
              <moduleName>Echo</moduleName>
              <acceptedCommands>
                  <command name='echo'>
                      <patterns>
                          <pattern>repite (.*)?</pattern>
                      </patterns>
                      <dataTypesRequired/>
                  </command>
              </acceptedCommands>
          </registerMessage>
      </message>";

   return $registerMessage;
}

# Get Bus
my $bus=Net::DBus->session();

# Export object
my $serviceToExport=$bus->export_service("com.trisvc.modules.Echo.default");
my $objectToExport=TrisvcEchoModule->new($serviceToExport);

# Get Brain Object
my $brainService=$bus->get_service("com.trisvc.modules.Brain.default");
my $brainObject=$brainService->get_object("/com/trisvc/modules/Brain/default", "com.trisvc.modules.BaseObject"); 

# Register Echo module
$brainObject->send(genRegisterMessage());

Net::DBus::Reactor->main->run();
 
exit 0;
