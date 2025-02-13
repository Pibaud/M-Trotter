import 'package:flutter/material.dart';

// Mapping des icônes par catégorie d'amenities
const Map<List<String>, IconData> amenityIconMapping = {
  ["bicycle_parking", "bicycle_rental", "bicycle_repair_station"]:
      Icons.pedal_bike_rounded,
  ["boat_rental", "boat_sharing", "boat_school"]: Icons.directions_boat_rounded,
  ["car_rental", "car_sharing", "car_pooling", "driving_school"]: Icons.directions_car_rounded,
  ["motorcycle_rental", "motorcycle_parking"]: Icons.motorcycle_rounded,
  ["parking", "parking_space", "parking_entrance"]: Icons.local_parking_rounded,
  ["taxi"]: Icons.local_taxi_rounded,
  ["ferry_terminal"]: Icons.directions_ferry_rounded,

  ["restaurant", "restaurant;bar", "cafe", "fast_food", "food_court"]:
      Icons.restaurant_rounded,
  ["bar", "pub", "nightclub", "hookah_lounge"]: Icons.local_bar_rounded,
  ["bbq"]: Icons.outdoor_grill_rounded,
  ["ice_cream"]: Icons.icecream_rounded,

  ["atm", "bank", "money_transfer", "bureau_de_change"]:
      Icons.account_balance_wallet_rounded,

  ["clinic", "dentist", "doctors", "hospital", "nursing_home", "healthcare"]:
      Icons.local_hospital_rounded,
  ["pharmacy"]: Icons.local_pharmacy_rounded,
  ["audiologist"]: Icons.hearing_rounded,
  ["veterinary", "dog_toilet"]: Icons.pets_rounded,
  ["pedicurist", "beauty", "personal_service"]: Icons.spa_rounded,
  ["yoga"]: Icons.self_improvement_rounded,
  ["gym", "dojo"]: Icons.fitness_center_rounded,

  ["school", "university", "college", "prep_school", "professional_school",
   "language_school", "training"]: Icons.school_rounded,
  ["library", "library_dropoff", "public_bookcase"]: Icons.local_library_rounded,
  ["music_school", "dance_school", "studio"]: Icons.music_note_rounded,
  ["theatre", "cinema", "auditorium", "conference_centre"]: Icons.theaters_rounded,
  ["arts_centre"]: Icons.palette_rounded,

  ["police", "fire_station"]: Icons.local_police_rounded,
  ["courthouse"]: Icons.gavel_rounded,
  ["townhall"]: Icons.account_balance_rounded,
  ["post_office", "post_box", "letter_box"]: Icons.local_post_office_rounded,

  ["place_of_worship"]: Icons.church_rounded,
  ["community_centre", "social_centre", "social_club", "childcare", "social_facility"]: Icons.groups_rounded,
  ["shelter"]: Icons.home,
  ["employment_agency", "job_centre"]: Icons.business_center_rounded,

  ["casino"]: Icons.casino_rounded,
  ["music_venue"]: Icons.audiotrack_rounded,
  ["events_venue"]: Icons.event_rounded,
  ["meeting_point"]: Icons.location_pin,
  ["marketplace"]: Icons.storefront_rounded,

  ["drinking_water", "water_point", "fountain"]: Icons.water_rounded,
  ["waste_basket", "recycling", "waste_disposal"]: Icons.delete_rounded,
  ["toilets", "public_bath", "shower"]: Icons.wc_rounded,
  ["laundry", "lavoir"]: Icons.local_laundry_service_rounded,
  ["charging_station", "device_charging_station"]:
      Icons.battery_charging_full_rounded,
  ["compressed_air", "vacuum_cleaner"]: Icons.electrical_services_rounded,
  ["ticket_validator"]: Icons.confirmation_number_rounded,

  ["locker", "locker_room"]: Icons.lock_rounded,
  ["bench", "table"]: Icons.chair_rounded
};

// Mapping des couleurs associées
const Map<List<String>, Color> amenityColorMapping = {
  ["bicycle_parking", "bicycle_rental", "bicycle_repair_station"]: Colors.green,
  ["boat_rental", "boat_sharing", "boat_school"]: Colors.blue,
  ["car_rental", "car_sharing", "car_pooling"]: Colors.orange,
  ["motorcycle_rental", "motorcycle_parking"]: Colors.orangeAccent,
  ["parking", "parking_space", "parking_entrance"]: Colors.lightBlue,
  ["taxi"]: Colors.yellow,
  ["ferry_terminal"]: Colors.blueAccent,

  ["restaurant", "restaurant;bar", "cafe", "fast_food", "food_court"]: Colors.red,
  ["bar", "pub", "nightclub", "hookah_lounge"]: Colors.deepPurple,
  ["bbq"]: Colors.brown,
  ["ice_cream"]: Colors.pinkAccent,

  ["atm", "bank", "money_transfer", "bureau_de_change"]: Colors.blueGrey,

  ["clinic", "dentist", "doctors", "hospital", "nursing_home", "healthcare"]: Colors.redAccent,
  ["pharmacy"]: Colors.teal,
  ["audiologist"]: Colors.indigo,
  ["veterinary", "dog_toilet"]: Colors.lightGreen,
  ["pedicurist", "beauty", "personal_service"]: Colors.purple,
  ["yoga"]: Colors.lightBlue,
  ["gym", "dojo"]: Colors.deepOrange,

  ["school", "university", "college", "prep_school", "professional_school",
   "language_school", "training"]: Colors.brown,
  ["library", "library_dropoff", "public_bookcase"]: Colors.brown,
  ["music_school", "dance_school", "studio"]: Colors.pink,
  ["theatre", "cinema", "auditorium"]: Colors.deepOrange,
  ["arts_centre"]: Colors.purple,

  ["police", "fire_station"]: Colors.blue,
  ["courthouse"]: Colors.grey,
  ["townhall"]: Colors.blue,
  ["post_office", "post_box", "letter_box"]: Colors.red,

  ["place_of_worship"]: Colors.amber,
  ["community_centre", "social_centre", "social_club"]: Colors.orange,
  ["shelter"]: Colors.blueGrey,
  ["employment_agency", "job_centre"]: Colors.teal,

  ["casino"]: Colors.deepPurple,
  ["music_venue"]: Colors.pinkAccent,
  ["events_venue"]: Colors.blueAccent,
  ["meeting_point"]: Colors.red,
  ["marketplace"]: Colors.green,

  ["drinking_water", "water_point"]: Colors.blue,
  ["waste_basket", "recycling", "waste_disposal"]: Colors.grey,
  ["toilets", "public_bath", "shower"]: Colors.lightBlue,
  ["laundry", "lavoir"]: Colors.blueGrey,
  ["charging_station", "device_charging_station"]: Colors.green,
  ["compressed_air", "vacuum_cleaner"]: Colors.yellow,
  ["ticket_validator"]: Colors.orange,

  ["locker", "locker_room"]: Colors.blueGrey,
  ["bench", "table"]: Colors.brown
};

IconData getAmenityIcon(String amenity) {
  for (var entry in amenityIconMapping.entries) {
    if (entry.key.contains(amenity)) {
      return entry.value;
    }
  }
  return Icons.location_on; // Icône par défaut
}

Color getAmenityColor(String amenity) {
  for (var entry in amenityColorMapping.entries) {
    if (entry.key.contains(amenity)) {
      return entry.value;
    }
  }
  return Colors.red; // Couleur par défaut
}
