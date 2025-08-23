"use client";

import React, { useState } from "react";

interface State {
  name: string;
  active: boolean;
}

interface CountryStateRow {
  id?: number;
  country: string;
  states: State[];
  active: boolean;
}

interface Props {
  countries: CountryStateRow[];
  onToggleActive: (id: number | undefined, active: boolean) => void;
  onSave: (updatedCountry: CountryStateRow) => void;
}

export default function EditableCountryList({ countries, onToggleActive, onSave }: Props) {
  const [expandedId, setExpandedId] = useState<number | undefined>(undefined);
  const [editData, setEditData] = useState<CountryStateRow | null>(null);

  const startEditing = (country: CountryStateRow) => {
    setExpandedId(country.id);
    setEditData({ ...country });
  };

  const cancelEditing = () => {
    setExpandedId(undefined);
    setEditData(null);
  };

  const updateStateName = (index: number, newName: string) => {
    if (!editData) return;
    const newStates = [...editData.states];
    newStates[index] = { ...newStates[index], name: newName };
    setEditData({ ...editData, states: newStates });
  };

  const toggleStateActive = (index: number, active: boolean) => {
    if (!editData) return;
    const newStates = [...editData.states];
    newStates[index] = { ...newStates[index], active };
    setEditData({ ...editData, states: newStates });
  };

  const addState = () => {
    if (!editData) return;
    setEditData({ ...editData, states: [...editData.states, { name: "", active: true }] });
  };

  const removeState = (index: number) => {
    if (!editData) return;
    const newStates = editData.states.filter((_, i) => i !== index);
    setEditData({ ...editData, states: newStates });
  };

  const saveChanges = () => {
    if (editData) {
      onSave(editData);
      cancelEditing();
    }
  };

  return (
    <div>
      <h3 className="text-lg font-semibold mb-3">Countries List</h3>
      {countries.map((country) => (
        <div key={country.id} className="mb-4 border p-3 rounded">
          <div className="flex justify-between items-center">
            <div>
              <input
                type="checkbox"
                checked={!!country.active}
                onChange={(e) => onToggleActive(country.id, e.target.checked)}
                className="mr-2"
              />
              <strong>{country.country}</strong>
            </div>
            <button
              className="text-blue-600 underline"
              onClick={() =>
                expandedId === country.id ? cancelEditing() : startEditing(country)
              }
            >
              {expandedId === country.id ? "Collapse" : "Edit"}
            </button>
          </div>

          {expandedId === country.id && editData && (
            <div className="mt-3">
              <label>
                Country Name:
                <input
                  type="text"
                  value={editData.country}
                  onChange={(e) => setEditData({ ...editData, country: e.target.value })}
                  className="border rounded px-2 py-1 ml-2"
                />
              </label>

              <div className="mt-2">
                <strong>States:</strong>
                {editData.states.map((state, idx) => (
                  <div key={idx} className="flex items-center mb-1">
                    <input
                      type="text"
                      value={state.name}
                      onChange={(e) => updateStateName(idx, e.target.value)}
                      className="border rounded px-2 py-1 flex-grow"
                    />
                    <input
                      type="checkbox"
                      checked={state.active}
                      onChange={(e) => toggleStateActive(idx, e.target.checked)}
                      className="ml-2"
                      title="Active"
                    />
                    <button
                      onClick={() => removeState(idx)}
                      className="ml-2 text-red-600"
                      title="Remove state"
                    >
                      &times;
                    </button>
                  </div>
                ))}
                <button
                  onClick={addState}
                  className="mt-1 px-3 py-1 bg-green-500 text-white rounded"
                >
                  Add State
                </button>
              </div>

              <div className="mt-3">
                <button
                  onClick={saveChanges}
                  className="mr-2 px-4 py-2 bg-blue-600 text-white rounded"
                >
                  Save
                </button>
                <button onClick={cancelEditing} className="px-4 py-2 border rounded">
                  Cancel
                </button>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

