package VBWallpapers::Plugins;

#VBWallpapers plugins
#This is the plugins module
#It's the default prototype of a plugins module
#All plugins need to define their name and to run initialize after
#Their need to define getWallpaper too for core module

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
use VBWallpapers::Core qw(getBrowser getRandom getCoreConfig);

#Any plugins need to copy this part and to change the name 'Module' to a more appropriate one
sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;

    $self->{'name'} = 'Module';

    $self->initialize();

    return $self;
}


#initialize all defaut value
sub initialize {
    $self = shift;

    #get global config
    $self->{'config'}{'system'} = getCoreConfig('system');
    $self->{'config'}{'module'} = getCoreConfig('modulesconf','ningen');

    #set default values
    $self->{'config'}{'module'}->{'maxerrors'} = 3 if ! defined $self->{'config'}{'module'}->{'maxerrors'};

    #errors quota before desactivating module
    $self->{'errors'} = $self->{'config'}{'module'}->{'maxerrors'};

    #browser
    $self->{'browser'} = getBrowser;

    #cache system
    $self->{"cache"} = {};
}

#usefull for saving specific config
sub getConfig {
    my $self = shift;

    return $self->{'config'}{'module'};
}

#usefull for getting one wallpapers link
sub getWallpaper {
    return;
}

#usefull for knowing if module is active or not
sub isActive {
    my $self = shift;
    return $self->{'errors'} > 0;
}
1;
