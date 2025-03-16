import React, { useState, useEffect, useRef } from 'react';
import { X } from 'lucide-react';
import { Tag } from '../types';

interface TagInputProps {
  value: string[];
  onChange: (tags: string[]) => void;
  suggestions?: Tag[];
  placeholder?: string;
  required?: boolean;
  error?: string;
}

const TagInput: React.FC<TagInputProps> = ({
  value = [],
  onChange,
  suggestions = [],
  placeholder = 'Add tags...',
  required = false,
  error
}) => {
  const [inputValue, setInputValue] = useState('');
  const [filteredSuggestions, setFilteredSuggestions] = useState<Tag[]>([]);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Filter suggestions based on input value
  useEffect(() => {
    if (inputValue.trim()) {
      const filtered = suggestions.filter(
        (suggestion) =>
          suggestion.name.toLowerCase().includes(inputValue.toLowerCase()) &&
          !value.includes(suggestion.name.toLowerCase())
      );
      setFilteredSuggestions(filtered);
    } else {
      // When no input, show all unused suggestions
      setFilteredSuggestions(
        suggestions.filter(
          (suggestion) => !value.includes(suggestion.name.toLowerCase())
        )
      );
    }
  }, [inputValue, suggestions, value]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (value.length === 0) {
      setInputValue(e.target.value);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && inputValue.trim() && value.length === 0) {
      e.preventDefault();
      addTag(inputValue);
    } else if (e.key === 'Backspace' && !inputValue && value.length > 0) {
      removeTag(value[0]);
    }
  };

  const addTag = (tagName: string) => {
    const normalizedTag = tagName.toLowerCase().trim();
    if (normalizedTag && value.length === 0) {
      onChange([normalizedTag]);
      setInputValue('');
    }
  };

  const removeTag = (tagToRemove: string) => {
    onChange([]);
    inputRef.current?.focus();
  };

  const handleSuggestionClick = (suggestion: Tag) => {
    if (value.length === 0) {
      addTag(suggestion.name);
      inputRef.current?.focus();
    }
  };

  return (
    <div className="space-y-1">
      <div className="flex items-center gap-2">
        <label className="text-sm font-medium text-text-light dark:text-text-dark">
          Tags *
          <span className="ml-2 text-xs text-primary-light dark:text-primary-dark">
            (select one)
          </span>
        </label>
      </div>

      <div className="relative" ref={containerRef}>
        <div className={`flex items-center gap-2 px-3 py-2 rounded-md border ${
          error 
            ? 'border-red-500 dark:border-red-400 focus-within:ring-red-500 dark:focus-within:ring-red-400' 
            : 'border-border-light dark:border-border-dark focus-within:ring-primary-light dark:focus-within:ring-primary-dark'
        } focus-within:outline-none focus-within:ring-2 bg-card-light dark:bg-card-dark`}>
          {value.length > 0 && (
            <div className="flex items-center gap-1 bg-primary-light dark:bg-primary-dark px-2 py-1 rounded-full text-white text-sm">
              <span>{value[0]}</span>
              <button
                onClick={() => removeTag(value[0])}
                className="hover:text-white/80 focus:outline-none"
              >
                <X size={14} />
              </button>
            </div>
          )}
          <input
            ref={inputRef}
            type="text"
            value={inputValue}
            onChange={handleInputChange}
            onKeyDown={handleKeyDown}
            className={`flex-1 bg-transparent focus:outline-none text-text-light dark:text-text-dark placeholder-muted-light dark:placeholder-muted-dark ${
              value.length > 0 ? 'w-12' : 'w-full'
            }`}
            placeholder={value.length === 0 ? placeholder : ''}
            required={required && value.length === 0}
          />
        </div>

        {value.length === 0 && (
          <div className="mt-2">
            <div className="text-xs text-muted-light dark:text-muted-dark mb-1">
              Suggested tags
            </div>
            <div className="flex flex-wrap gap-2">
              {suggestions.map((suggestion) => (
                <button
                  key={suggestion.id}
                  onClick={() => handleSuggestionClick(suggestion)}
                  className="px-2 py-1 bg-background-light dark:bg-background-dark hover:bg-primary-light hover:text-white dark:hover:bg-primary-dark dark:hover:text-white border border-border-light dark:border-border-dark hover:border-primary-light dark:hover:border-primary-dark rounded-full text-sm transition-colors"
                >
                  {suggestion.name}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {error && (
        <p className="text-sm text-red-500 dark:text-red-400">{error}</p>
      )}
    </div>
  );
};

export default TagInput;