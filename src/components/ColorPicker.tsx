import React, { useState, useEffect } from 'react';
import { RefreshCw, Save } from 'lucide-react';

interface ColorPickerProps {
  colors: {
    primary: string;
    secondary: string;
    body: string;
    card: string;
  };
  onChange: (colors: {
    primary: string;
    secondary: string;
    body: string;
    card: string;
  }) => void;
  onPreview: (colors: {
    primary: string;
    secondary: string;
    body: string;
    card: string;
  }) => void;
  onReset: () => void;
}

const ColorPicker: React.FC<ColorPickerProps> = ({
  colors: initialColors,
  onChange,
  onPreview,
  onReset,
}) => {
  const [colors, setColors] = useState(initialColors);
  const [isDirty, setIsDirty] = useState(false);
  const [baseColors, setBaseColors] = useState(initialColors);

  // Update colors when initialColors change, but preserve isDirty correctly
  useEffect(() => {
    // Compare new initialColors with baseColors to determine if we should reset
    const hasChangesFromBase = Object.keys(initialColors).some(
      (key) => initialColors[key] !== baseColors[key]
    );

    // Update colors to match new initialColors
    setColors(initialColors);

    // If initialColors differ from baseColors, don't reset isDirty
    // Only reset isDirty if they're the same (e.g., after a save or reset)
    if (!hasChangesFromBase) {
      console.log('::no changes from base, resetting isDirty');
      setIsDirty(false);
    } else {
      console.log('::changes detected from base, preserving isDirty');
    }

    // Always update baseColors to match new initialColors
    setBaseColors(initialColors);
  }, [initialColors]);

  const handleColorChange = (key: keyof typeof colors, value: string) => {
    const newColors = {
      ...colors,
      [key]: value,
    };
    setColors(newColors);

    // Check if the new colors differ from baseColors
    const hasChanges = Object.keys(newColors).some(
      (k) => newColors[k] !== baseColors[k]
    );
    setIsDirty(hasChanges);
    onPreview(newColors);
  };

  const handleSave = () => {
    onChange(colors);
    setBaseColors(colors); // Update baseColors after saving
    setIsDirty(false);
  };

  const handleReset = () => {
    setColors(baseColors);
    setIsDirty(false);
    onPreview(baseColors);
    onReset();
  };

  const handleCancel = () => {
    setColors(baseColors);
    setIsDirty(false);
    onPreview(baseColors);
  };

  // Rest of the JSX remains unchanged
  return (
    <div className="p-4 rounded-lg border border-border-light dark:border-border-dark bg-card-light dark:bg-card-dark">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-sm font-medium text-text-light dark:text-text-dark">
          Customize Colors
        </h3>
        <div className="flex gap-2">
          {isDirty && (
            <button
              onClick={handleCancel}
              className="flex items-center gap-1 text-sm text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark transition-colors"
            >
              <span>Cancel</span>
            </button>
          )}
          <button
            onClick={handleReset}
            className="flex items-center gap-1 text-sm text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark transition-colors"
            title="Reset to original colors"
          >
            <RefreshCw size={14} />
            <span>Reset</span>
          </button>
          <button
            onClick={handleSave}
            disabled={!isDirty}
            className={`flex items-center gap-1 text-sm px-3 py-1 rounded-md transition-colors ${
              isDirty
                ? 'bg-primary-light dark:bg-primary-dark text-white hover:bg-opacity-90'
                : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed'
            }`}
          >
            <Save size={14} />
            <span>Save Changes</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-xs font-medium text-text-light dark:text-text-dark mb-1">
            Primary Color
          </label>
          <div className="flex gap-2">
            <input
              type="color"
              value={colors.primary}
              onChange={(e) => handleColorChange('primary', e.target.value)}
              className="h-8 w-16 rounded cursor-pointer"
            />
            <input
              type="text"
              value={colors.primary}
              onChange={(e) => handleColorChange('primary', e.target.value)}
              className="flex-1 px-2 py-1 text-sm rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-1 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
              pattern="^#[0-9A-Fa-f]{6}$"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-medium text-text-light dark:text-text-dark mb-1">
            Secondary Color
          </label>
          <div className="flex gap-2">
            <input
              type="color"
              value={colors.secondary}
              onChange={(e) => handleColorChange('secondary', e.target.value)}
              className="h-8 w-16 rounded cursor-pointer"
            />
            <input
              type="text"
              value={colors.secondary}
              onChange={(e) => handleColorChange('secondary', e.target.value)}
              className="flex-1 px-2 py-1 text-sm rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-1 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
              pattern="^#[0-9A-Fa-f]{6}$"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-medium text-text-light dark:text-text-dark mb-1">
            Body Color
          </label>
          <div className="flex gap-2">
            <input
              type="color"
              value={colors.body}
              onChange={(e) => handleColorChange('body', e.target.value)}
              className="h-8 w-16 rounded cursor-pointer"
            />
            <input
              type="text"
              value={colors.body}
              onChange={(e) => handleColorChange('body', e.target.value)}
              className="flex-1 px-2 py-1 text-sm rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-1 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
              pattern="^#[0-9A-Fa-f]{6}$"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-medium text-text-light dark:text-text-dark mb-1">
            Card Color
          </label>
          <div className="flex gap-2">
            <input
              type="color"
              value={colors.card}
              onChange={(e) => handleColorChange('card', e.target.value)}
              className="h-8 w-16 rounded cursor-pointer"
            />
            <input
              type="text"
              value={colors.card}
              onChange={(e) => handleColorChange('card', e.target.value)}
              className="flex-1 px-2 py-1 text-sm rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-1 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
              pattern="^#[0-9A-Fa-f]{6}$"
            />
          </div>
        </div>
      </div>

      <div className="mt-4">
        <div className="text-xs font-medium text-text-light dark:text-text-dark mb-2">
          Preview
        </div>
        <div
          className="p-4 rounded-lg"
          style={{ backgroundColor: colors.body }}
        >
          <div
            className="p-4 rounded-lg mb-2"
            style={{ backgroundColor: colors.card }}
          >
            <div
              className="h-6 w-24 rounded mb-2"
              style={{ backgroundColor: colors.primary }}
            />
            <div
              className="h-3 w-32 rounded"
              style={{ backgroundColor: colors.secondary }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default ColorPicker;
