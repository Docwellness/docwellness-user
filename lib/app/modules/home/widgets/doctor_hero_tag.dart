/// Shared Hero tag between the Home "About Me" card's photo thumbnail
/// (about_me_section.dart) and the About Doctor page's header photo
/// (doctor_detail_view.dart) - tapping the card morphs the photo directly
/// into the detail page's header instead of the two screens feeling
/// disconnected. Lives in its own file so neither widget file has to
/// import the other just to share this constant.
const String doctorPhotoHeroTag = 'doctor-photo-hero';
