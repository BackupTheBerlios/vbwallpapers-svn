package VBWallpapers::plugins::ningen;

#VBWallpapers plugins ningen
#This is the plugin Ningen Natoli
#They load wallpaper from: http://ningen.nattoli.net/wallpapers/lthruz/


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

#TODO: 
#     allow people to choose their resolution from config file

#Load all necessary module
use VBWallpapers::Core qw(getBrowser getRandom getCoreConfig);

#Define version and ISA for inheritance
use vars qw($VERSION @ISA);

$VERSION = '0.01'; #Date: 2006/01/03 13:30

#Inherit from VBWallpapers::Plugins
use base VBWallpapers::Plugins;

#Default new method
sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->{'name'} = 'Ningen';
    $self->initialize();
    return $self;
}

#usefull for getting one wallpapers link
sub getWallpaper {
    my $self = shift;
    print $self->{'name'},": getting wallpaper ...\n";

    #Use cache method for reduce loading time of the server
    if ((scalar keys %{$self->{"cache"}}) == 0) {
	print($self->{'name'},": Links empty ... Filling it ...\n");
	$self->{"browser"}->get("http://ningen.nattoli.net/wallpapers/lthruz/");
	if ($self->{"browser"}->success()) {
	    #Get all 1280x960 link
	    foreach my $link ($self->{"browser"}->find_all_links(url_abs_regex => qr/-0960/)) {
		$self->{"cache"}->{$link->url_abs()}={};
	    }
	    #No link found ... Error
	    if ((scalar keys %{$self->{"cache"}}) == 0) {
		print($self->{'name'},": Links empty ... Sorry ...\n");
		$self->{'errors'}--;
		return;
	    } else {
		print($self->{'name'},": Found ", scalar keys %{$self->{"cache"}} ," links ...\n");
	    }
	}else{
	    print($self->{'name'},": Getting links failed ...\n");
	    $self->{'errors'}--;
	    return;
	}
    }else{
	print($self->{'name'},": Links not empty ... Skip fill ...\n");
    }

    #Get any of it, delete it after
    my $randomWallpaper = getRandom($self->{"cache"});
    delete $self->{"cache"}->{$randomWallpaper};
    return $randomWallpaper;
}

1;
