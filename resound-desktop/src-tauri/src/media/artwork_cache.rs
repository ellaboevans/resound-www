use std::collections::HashMap;
use std::sync::Mutex;

pub struct ArtworkCache {
    cache: Mutex<HashMap<String, String>>,
}

impl ArtworkCache {
    pub fn new() -> Self {
        Self {
            cache: Mutex::new(HashMap::new()),
        }
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.cache.lock().ok()?.get(key).cloned()
    }

    pub fn set(&self, key: String, value: String) {
        if let Ok(mut cache) = self.cache.lock() {
            cache.insert(key, value);
        }
    }
}
