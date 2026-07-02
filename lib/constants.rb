# frozen_string_literal: true

# Constants copied from searchworks. Kept as a top-level Constants module so the
# diff against searchworks' lib/constants.rb stays small for re-syncs.
module Constants
  SUL_ICON_COMPONENTS = {
    'Loose-leaf' => Icons::LooseLeafComponent,
    'Object' => Icons::CubeComponent,
    'Academic Journal' => Icons::Book2Component,
    'Archive/Manuscript' => Icons::DocumentBox1Component,
    'Archived website' => Icons::NetworkWebComponent,
    'Article' => Icons::TextWrapping1Component,
    'Book' => Icons::Book1Component,
    'Dataset' => Icons::BusinessChart1Component,
    'Database' => Icons::WindowSearchComponent,
    'Equipment' => Icons::Plug2Component,
    'Image' => Icons::Photos1Component,
    'Journal/Periodical' => Icons::Book2Component,
    'Map' => Icons::MapLocationComponent,
    'Music recording' => Icons::GramophoneComponent,
    'Music score' => Icons::FileMusicComponent,
    'Newspaper' => Icons::Newspaper2Component,
    'Software/Multimedia' => Icons::Mouse2Component,
    'Sound recording' => Icons::Microphone2Component,
    'Video' => Icons::Film2Component, # old format_main_ssim value
    'Video/Film' => Icons::Film2Component,
    'Video game' => Icons::GameController2Component,
    'Website' => Icons::NetworkWebComponent,
    'Credits' => Icons::Contacts1Component,
    'Subjects' => Icons::Tags1Component,
    'Contents' => Icons::List4Component,
    'Browse' => Icons::Books3Component,
    'Chat' => Icons::Bubble2Component,
    'Feedback' => Icons::Mail1Component,
    'Cite' => Icons::QuoteComponent,
    'Send To' => Icons::LinkComponent,
    'Selections' => Icons::Check3Component
  }.freeze
end
