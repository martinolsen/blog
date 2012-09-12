#!/usr/bin/env perl
use Modern::Perl;

use File::Slurp;
use Mojo::DOM;
use Template;
use Text::Markdown 'markdown';

my $template = Template->new();

my @index;

# Process articles
for my $file (glob "article/*.mkd") {
    unless($file =~ m|^article/(\d+)-(.*)\.mkd$|) {
        die "invalid article name: $file";
    }

    my $date = $1;
    my $name = $2;

    say " $name ($date)";

    # Render markdown into HTML
    my $body = markdown(scalar read_file($file));

    my $dom = Mojo::DOM->new($body);

    my $article = {
        date => $date,
        name => $name,
        url => "$name.html",
        title => $dom->at('h1')->text,
    };

    # Render final page
    $template->process(
        'template/article.tt2',
        { body => $body, article => $article },
        "output/$article->{name}.html"
    ) or die "error processing article.tt2: " . $template->error();

    push @index, $article;
}

$template->process(
    'template/index.tt2',
    { index => [ reverse sort { $a->{date} <=> $b->{date} } @index ] },
    'output/index.html'
) or die "error processing index.tt2: " . $template->error();
