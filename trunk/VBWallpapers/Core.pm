package VBWallpapers::Core;

use strict;
use WWW::Mechanize;
use Digest::MD5 qw(md5_hex);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %config);

$VERSION = '0.01'; #Date: 2006/01/03 13:30

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(getRandom getBrowser getCoreConfig getWallpaper setWallpaper);


use Data::Dumper;

#getRandom
# return random keys of an hash
sub getRandom {
    my $tabparams = shift;
    my @tab;
    if (ref $tabparams eq 'ARRAY') {
	@tab = @{$tabparams};
    } else {
	@tab = keys %$tabparams;
    }
    if ($#tab < 0) {
	return;
    } else {
	return $tab[rand($#tab+1)];
    }
}

sub getRandomPluginName {
    my @pluginslist = keys %{$config{'modules'}};
    my @pluginslistavailable;
    foreach my $pluginname (@pluginslist) {
	push @pluginslistavailable, $pluginname if ($config{'modules'}{$pluginname}->isActive);
    }
    return getRandom \@pluginslistavailable;
}

#getBrowser
# create a browser and return it
sub getBrowser {
    my $browser = WWW::Mechanize->new();
    $browser->agent_alias( 'Linux Mozilla' );
    $browser->timeout(15);
    $browser->stack_depth(1);
    return $browser;
}

#trim
# cleanup left and right space
sub trim {
    foreach(@_) {
	s/^\s*(.*?)\s*$/$1/;
    }
}

#getCoreConfig
# return global config of application
# allow to go in sub node of config
# params:
#  array
sub getCoreConfig {
    my $currentconfig = \%config;

    foreach my $sub (@_) {
	$currentconfig = $currentconfig->{$sub};
	last if not defined $currentconfig;
    }
    return $currentconfig;
}

#saveConfig
# ask to all module their config
# write it properly to config module file
sub saveConfig {
    open F, ">$config{'system'}{'configfile'}";
    for my $left (keys %{$config{'systemconf'}}) {
	print F $left,'=',$config{'systemconf'}{$left},"\n";
    }
    for my $pluginname (keys %{$config{'modules'}}) {
	print F '[',$pluginname,']',"\n";
	my $plugin = $config{'modules'}{$pluginname};
	my $conf = $plugin->getConfig;
	for my $left (keys %{$conf}){
	    print F $left,'=',$conf->{$left},"\n";
	}
    }
    close F;
}

#get wallpaper from any module available
sub getWallpaper {
    my $pluginname;
    my $wallpaper;

    while (!defined $wallpaper) {
	$pluginname = getRandomPluginName;
	return if ! defined $pluginname;
	print "Try with plugin: $pluginname ...\n";
	$wallpaper = $config{'modules'}{$pluginname}->getWallpaper;
    }

    saveConfig;

    return $wallpaper;
}

#set wallpaper with cmd
sub setWallpaper {
    my $wallpaper = shift;
    my $browser = getBrowser;
    my $cachewallpaper = $config{'system'}{'cachedir'}.'/'.md5_hex($wallpaper).'.jpg';

    #make cache
    if (! -e $cachewallpaper) {
	my $try = 3;
	while ($try-- > 0) {
	    print "Getting: ",$wallpaper," [ stay $try tries ... ]\n";
	    $browser->get($wallpaper);
	    if ($browser->success()) {
		my $ctype = $browser->{'res'}->{'_headers'}->{'content-type'};
		$ctype = @{$ctype}[0]if (ref $ctype eq 'ARRAY');
		my $clength = $browser->{'res'}->{'_headers'}->{'content-length'};
		print "Type: ",$ctype," | Length: ",$clength,"\n";
		next if $ctype ne 'image/jpeg' or $clength < 32768;
		$browser->save_content($cachewallpaper);
		last;
	    }
	}
    }


    if (-e $cachewallpaper) {
	my $cmd = $config{'systemconf'}{'setwallpapercmd'};
	if (defined $cmd) {
	    $cmd =~ s/\%s/$cachewallpaper/;
	}
	system($cmd);
	return 1;
    }
    return 0;
}

#init
# initialise wallpaper
sub init {
    #set initiale dir
    $config{'system'}{'workingdir'} = $ENV{'HOME'}."/.vbwallpapers";
    $config{'system'}{'pluginsdir'} = $config{'system'}{'workingdir'}."/plugins";
    $config{'system'}{'cachedir'}   = $config{'system'}{'workingdir'}."/cache";
    $config{'system'}{'configfile'} = $config{'system'}{'workingdir'}."/vbwallpapers.conf";

    #add user working dir to INC search path
    eval("use lib '$config{'system'}{'workingdir'}'");

    print "Loading configuration files ...\n";

    #creating home dir for saving file
    if (! -e $config{'system'}{'workingdir'}) {
	mkdir($config{'system'}{'workingdir'});
	mkdir($config{'system'}{'pluginsdir'});
	mkdir($config{'system'}{'cachedir'});
    }

    #Load config file for module
    open F, "<$config{'system'}{'configfile'}";
    my @cfg = <F>;
    close F;

    my $block = '';

    foreach my $line (@cfg) {
	chomp($line);
	$line =~ s/#.*//;
	my ($left, $right) = split (/=/,$line);
        trim($left, $right);

	if ($left =~ /^\[.*\]$/) {
	    ($block) = ($left =~ /^\[(.*)\]$/);
	}else{
	    if (length($left)>0) {
		$config{'modulesconf'}{$block}{$left}=$right;
	    }else{
		$config{'systemconf'}{$block}{$left}=$right;
	    }
	}
    }

    #set default systemconf
    $config{'systemconf'}{'setwallpapercmd'} = 'dcop kdesktop KBackgroundIface setWallpaper "%s" 4' if ! defined $config{'systemconf'}{'setwallpapercmd'};


    #Loading module
    print "Modules ...\n";
    my @pluginsfiles = `find "$config{'system'}{'pluginsdir'}" -name \*.pm`;
    foreach my $plugin(@pluginsfiles) {

	#cleanup plugin find result
	chomp($plugin);
	my $pluginfile = $plugin;
	$plugin =~ s/^$config{'system'}{'workingdir'}\/(.*?).pm$/$1/;
	$plugin = 'VBWallpapers::'.$plugin;
	$plugin =~ s/\//::/g;

	#drop from plugin pluginsdir name
	my $pluginname = $plugin;
	$pluginname =~ s/.*:://;

	#Try to load plugin
	print "Loading $plugin ...";
	eval("require \"$pluginfile\"");
	print " [ OK  ] \n";
	$config{'modules'}{$pluginname} = new $plugin;
    }

}

init;

1;
