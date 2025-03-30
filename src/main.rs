use rand::Rng;
use std::time::SystemTime;

fn main() {
    // Get current timestamp for seed
    let seed = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_secs();

    // Initialize random number generator
    let mut rng = rand::SeedableRng::from_seed(seed);

    // Generate a random number between 1 and 100
    let winning_number = rng.gen_range(1..=100);

    println!("Welcome to the Lottery Generator!");
    println!("The winning number is: {}", winning_number);
}