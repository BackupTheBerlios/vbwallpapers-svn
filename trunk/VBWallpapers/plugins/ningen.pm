package VBWallpapers::plugins::ningen;

use VBWallpapers::Core qw(getBrowser getRandom getCoreConfig);

use vars qw($VERSION @ISA);

$VERSION = '0.01'; #Date: 2006/01/03 13:30

#Inherit from VBWallpapers::Plugins
use base VBWallpapers::Plugins;

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


    if ((scalar keys %{$self->{"cache"}}) == 0) {
	print($self->{'name'},": Links empty ... Filling it ...\n");
	$self->{"browser"}->get("http://ningen.nattoli.net/wallpapers/lthruz/");
	if ($self->{"browser"}->success()) {
	    foreach my $link ($self->{"browser"}->find_all_links(url_abs_regex => qr/-0960/)) {
		$self->{"cache"}->{$link->url_abs()}={};
	    }
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

    my $randomWallpaper = getRandom($self->{"cache"});
    delete $self->{"cache"}->{$randomWallpaper};
    return $randomWallpaper;
}

1;
