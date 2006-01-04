package VBWallpapers::Core;

#VBWallpapers core
#This is the core module
#They give all function that plugins need
#They load all plugins automatically and use it for getting wallpapers

#Copyright (C) 2006 Bachelier Hoarau Vincent

#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


#Load all necessary module
use strict;
use WWW::Mechanize;           #Need for getting and browsing web site
use Digest::MD5 qw(md5_hex);  #Need for saving file with md5 of their address link

#Use exporter for allowing other program to use it's function
#%config is a hash that will contain all module and all configuration files
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %config);

$VERSION = '0.01'; #Date: 2006/01/03 13:30

#Exporting all global function
#Usefull for plugins and main application
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(getRandom getBrowser getCoreConfig getWallpaper setWallpaper);


#getRandom
# return random keys of an hash or and array
sub getRandom {
    my $tabparams = shift;
    my @tab;

    #Get key of an array or an hash
    if (ref $tabparams eq 'ARRAY') {
	@tab = @{$tabparams};
    } else {
	@tab = keys %$tabparams;
    }

    #Return random of these key	
    if ($#tab < 0) {
	return;
    } else {
	return $tab[rand($#tab+1)];
    }
}

#getRandomPluginName
# return any plugin name of active plugins
sub getRandomPluginName {

    #get all plugin name
    my @pluginslist = keys %{$config{'modules'}};

    #Fill this array with all still active plugin
    my @pluginslistavailable;
    foreach my $pluginname (@pluginslist) {
	push @pluginslistavailable, $pluginname if ($config{'modules'}{$pluginname}->isActive);
    }

    #return any of it
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
    print "Core: Saving configuration ...\n";

    open F, ">$config{'system'}{'configfile'}";

    #Write system conf part
    for my $left (keys %{$config{'systemconf'}}) {
	print F $left,'=',$config{'systemconf'}{$left},"\n";
    }

    #Write module conf part
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

    #Look any wallpaper from all module
    while (!defined $wallpaper) {
	$pluginname = getRandomPluginName;
	return if ! defined $pluginname;
	print "Try with plugin: $pluginname ...\n";
	$wallpaper = $config{'modules'}{$pluginname}->getWallpaper;
    }

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

#Save and Exit
# Usefull for signal below
sub saveAndExit {
    saveConfig;
    exit 0;
}

#Auto run init
init;

#Saveconfig before unloading Core module
#They capture all kill signal
#INT: interruption by use (CTRL + C)
#QUIT: Quit send signal
#TERM: killall default signal
$SIG{INT} = \&saveAndExit;
$SIG{QUIT} = \&saveAndExit;
$SIG{TERM} = \&saveAndExit;

1;
