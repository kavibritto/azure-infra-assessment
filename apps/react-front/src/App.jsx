import { useEffect, useState } from "react";
import axios from "axios";

export default function App() {
  const [items, setItems] = useState([]);
  const [form, setForm] = useState({ name: "", description: "", price: "" });
  const [editing, setEditing] = useState(null);

  const loadItems = async () => {
    const res = await axios.get("/api/v1/items");
    setItems(res.data);
  };

  useEffect(() => {
    loadItems();
  }, []);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (editing) {
      await axios.put(`/api/v1/items/${editing}`, {
        name: form.name,
        description: form.description,
        price: parseFloat(form.price),
      });
      setEditing(null);
    } else {
      await axios.post("/api/v1/items", {
        name: form.name,
        description: form.description,
        price: parseFloat(form.price),
      });
    }
    setForm({ name: "", description: "", price: "" });
    loadItems();
  };

  const handleEdit = (item) => {
    setEditing(item.id);
    setForm({
      name: item.name,
      description: item.description,
      price: item.price,
    });
  };

  const handleDelete = async (id) => {
    await axios.delete(`/api/v1/items/${id}`);
    loadItems();
  };

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-4">Echo CRUD Items</h1>

      <form onSubmit={handleSubmit} className="space-y-3 mb-6">
        <input
          name="name"
          value={form.name}
          onChange={handleChange}
          placeholder="Name"
          className="border p-2 w-full rounded"
          required
        />
        <input
          name="description"
          value={form.description}
          onChange={handleChange}
          placeholder="Description"
          className="border p-2 w-full rounded"
        />
        <input
          name="price"
          type="number"
          step="0.01"
          value={form.price}
          onChange={handleChange}
          placeholder="Price"
          className="border p-2 w-full rounded"
          required
        />
        <button
          type="submit"
          className="bg-blue-600 text-white px-4 py-2 rounded"
        >
          {editing ? "Update" : "Create"}
        </button>
      </form>

      <ul className="space-y-2">
        {items.map((item) => (
          <li
            key={item.id}
            className="border p-3 rounded flex justify-between items-center"
          >
            <div>
              <p className="font-semibold">{item.name}</p>
              <p className="text-sm text-gray-600">{item.description}</p>
              <p className="text-sm">₹{item.price}</p>
            </div>
            <div className="space-x-2">
              <button
                onClick={() => handleEdit(item)}
                className="px-3 py-1 bg-yellow-500 text-white rounded"
              >
                Edit
              </button>
              <button
                onClick={() => handleDelete(item.id)}
                className="px-3 py-1 bg-red-600 text-white rounded"
              >
                Delete
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
