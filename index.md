---
layout: home
author_profile: true
title: "Salesforce Developer's Tech Archive"
entries_layout: grid
header:
  overlay_color: "#032D60"
  overlay_filter: "0.7"
  excerpt: "Salesforce Developer | Application Architect | Agentforce Legend ⚡"
---

<link rel="stylesheet" href="{{ '/assets/css/hermes-style.css' | relative_url }}">

<div class="intro-wrapper">
  <h1>👋 Welcome!</h1>
  <p class="intro-text">
    I am a <span class="highlight">Salesforce Developer based in South Korea</span>, dedicated to building clean, scalable, and high-performance architectures. 
  </p>
  <p class="intro-subtext">
    This blog serves as a technical archive where I document the challenges encountered and solutions engineered while optimizing complex Salesforce environments. I am committed to sharing insights on <b>system design and clean code</b> every Wednesday.
  </p>
  
  <div class="skill-badges">
    <span>Apex</span> <span>LWC</span> <span>Python</span> <span>System Architect</span> <span>Agentforce</span>
  </div>
</div>

<hr class="section-divider">

### 🏆 Professional Achievements

<div class="cert-grid">
  {% for cert in site.data.mycerts %}
  <div class="cert-card">
    <div class="cert-header">
      <img src="{{ cert.image | relative_url }}" class="cert-badge-img">
    </div>
    <div class="cert-body">
      <h4>{{ cert.title }}</h4>
      <p class="cert-date">Issued {{ cert.date }}</p>
    </div>
  </div>
  {% endfor %}
</div>

<hr class="section-divider">

### ✍️ Recent Archive