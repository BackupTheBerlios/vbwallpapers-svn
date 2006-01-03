package VBWallpapers::Plugins;
use VBWallpapers::Core qw(getBrowser getRandom getCoreConfig);

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
