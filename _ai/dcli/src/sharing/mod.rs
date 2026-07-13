//! Module sharing functionality for uploading/downloading modules from community repository.
//!
//! This module provides:
//! - `SharingMetadata` struct for module metadata required for sharing
//! - Git operations for syncing with the remote repository
//! - Validation for ensuring modules meet sharing requirements

pub mod git;

use serde::{Deserialize, Serialize};

/// Standard categories for module organization in the repository
pub const VALID_CATEGORIES: &[&str] = &[
    "window-managers",
    "desktop-environments",
    "development",
    "gaming",
    "media",
    "productivity",
    "system",
    "networking",
    "tools",
    "packages",
    "other",
];

/// Metadata required for module sharing (upload/download)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SharingMetadata {
    /// Module author (GitHub/GitLab username) - required for upload
    pub author: String,

    /// Module version (semver format: X.Y.Z) - required for upload
    pub version: String,

    /// Module description - required for upload
    pub description: String,

    /// Category for repository organization (defaults to "other" if not specified)
    pub category: Option<String>,

    /// Tags for search/filtering
    pub tags: Vec<String>,

    /// License identifier (e.g., "MIT", "GPL-3.0")
    pub license: Option<String>,

    /// URL to upstream project/documentation
    pub upstream_url: Option<String>,
}

impl SharingMetadata {
    /// Validate metadata meets requirements for upload
    ///
    /// Returns Ok(()) if valid, or Err with a list of validation errors
    pub fn validate(&self) -> Result<(), Vec<String>> {
        let mut errors = Vec::new();

        // Check required fields
        if self.author.trim().is_empty() {
            errors.push("'author' field is required (your GitHub/GitLab username)".to_string());
        }

        if self.version.trim().is_empty() {
            errors.push("'version' field is required (semver format: X.Y.Z)".to_string());
        }

        if self.description.trim().is_empty() {
            errors.push("'description' field is required".to_string());
        }

        // Validate semver format (basic check: X.Y.Z with optional suffix)
        if !self.version.trim().is_empty() {
            let semver_pattern = regex::Regex::new(r"^\d+\.\d+\.\d+(-[\w.]+)?$").unwrap();
            if !semver_pattern.is_match(&self.version) {
                errors.push(format!(
                    "'version' must follow semver format (X.Y.Z), got: '{}'",
                    self.version
                ));
            }
        }

        // Validate category if provided
        if let Some(ref cat) = self.category {
            if !cat.trim().is_empty() && !VALID_CATEGORIES.contains(&cat.as_str()) {
                errors.push(format!(
                    "Invalid category '{}'. Valid categories: {}",
                    cat,
                    VALID_CATEGORIES.join(", ")
                ));
            }
        }

        if errors.is_empty() {
            Ok(())
        } else {
            Err(errors)
        }
    }

    /// Get the effective category (defaults to "other" if not specified or empty)
    pub fn effective_category(&self) -> &str {
        self.category
            .as_ref()
            .filter(|c| !c.trim().is_empty())
            .map(|c| c.as_str())
            .unwrap_or("other")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_metadata() {
        let meta = SharingMetadata {
            author: "testuser".to_string(),
            version: "1.0.0".to_string(),
            description: "A test module".to_string(),
            category: Some("development".to_string()),
            tags: vec!["test".to_string()],
            license: Some("MIT".to_string()),
            upstream_url: None,
        };
        assert!(meta.validate().is_ok());
    }

    #[test]
    fn test_missing_author() {
        let meta = SharingMetadata {
            author: "".to_string(),
            version: "1.0.0".to_string(),
            description: "A test module".to_string(),
            category: None,
            tags: vec![],
            license: None,
            upstream_url: None,
        };
        let errors = meta.validate().unwrap_err();
        assert!(errors.iter().any(|e| e.contains("author")));
    }

    #[test]
    fn test_invalid_version() {
        let meta = SharingMetadata {
            author: "testuser".to_string(),
            version: "invalid".to_string(),
            description: "A test module".to_string(),
            category: None,
            tags: vec![],
            license: None,
            upstream_url: None,
        };
        let errors = meta.validate().unwrap_err();
        assert!(errors.iter().any(|e| e.contains("semver")));
    }

    #[test]
    fn test_invalid_category() {
        let meta = SharingMetadata {
            author: "testuser".to_string(),
            version: "1.0.0".to_string(),
            description: "A test module".to_string(),
            category: Some("invalid-category".to_string()),
            tags: vec![],
            license: None,
            upstream_url: None,
        };
        let errors = meta.validate().unwrap_err();
        assert!(errors.iter().any(|e| e.contains("Invalid category")));
    }

    #[test]
    fn test_effective_category_default() {
        let meta = SharingMetadata {
            author: "testuser".to_string(),
            version: "1.0.0".to_string(),
            description: "A test module".to_string(),
            category: None,
            tags: vec![],
            license: None,
            upstream_url: None,
        };
        assert_eq!(meta.effective_category(), "other");
    }

    #[test]
    fn test_effective_category_empty() {
        let meta = SharingMetadata {
            author: "testuser".to_string(),
            version: "1.0.0".to_string(),
            description: "A test module".to_string(),
            category: Some("".to_string()),
            tags: vec![],
            license: None,
            upstream_url: None,
        };
        assert_eq!(meta.effective_category(), "other");
    }
}
