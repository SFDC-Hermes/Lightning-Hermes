---
layout: home
author_profile: true
title: "Salesforce Developer's Tech Archive"
entries_layout: grid
header:
  overlay_color: "#000"
  overlay_filter: "0.5"
  excerpt: "Salesforce Developer | Application Architect | AgentBlazer Legend"
---

<link rel="stylesheet" href="{{ '/assets/css/hermes-style.css' | relative_url }}">

# 👋 Welcome!

I am a **Salesforce Developer based in South Korea**, dedicated to building clean, scalable, and high-performance architectures. 

This blog is a record of my journey—documenting the challenges I’ve encountered and the solutions I’ve engineered while building and optimizing complex Salesforce projects. I believe that the process of solving real-world problems is where true growth happens. I'm committed to publishing one article every Wednesday.

### 🏆 Professional Achievements

<div class="cert-container">
  {% for cert in site.data.mycerts %}
  <div class="cert-item">
    <div class="cert-left">
      <img src="{{ cert.image | relative_url }}" class="cert-icon">
      <div class="cert-info">
        <h4>{{ cert.title }}</h4>
        <p>{{ cert.date }}</p>
      </div>
    </div>
    <div class="cert-right">
      <span class="status-badge">Active</span>
    </div>
  </div>
  {% endfor %}
</div>

---
