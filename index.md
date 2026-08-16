---
layout: home
author_profile: true
title: "Salesforce Developer's Tech Archive"
entries_layout: grid
classes: wide  
header:
  overlay_color: "white"
  overlay_filter: "0.7"
  excerpt: "Salesforce Developer | Application Architect | Agentforce Legend ⚡"
---

<link rel="stylesheet" href="{{ '/assets/css/hermes-style.css' | relative_url }}">

<div class="intro-wrapper">
  <h1>👋 Welcome!</h1>
  <p class="intro-text">
    I am a <span class="highlight">Salesforce & Agentforce Developer based in South Korea</span>, dedicated to building clean, scalable, and high-performance architectures.
  </p>
  <p class = "intro-subtext">
    I can't share the exact code or details from my actual projects, but I plan to consistently post and refine the <b>foundational concepts</b> behind them.
  </p>
  <p class="intro-subtext">
    This blog serves as a technical archive for system design and clean code. I document complex engineering challenges and the architectural solutions derived from my real-world Salesforce projects. <b>While     the technical substance and logic are rooted in my direct professional experience, the narratives of these posts are refined in collaboration with AI.</b>
  </p>
  
  <div class="skill-badges">
    <span>Apex</span> <span>LWC</span> <span>Data</span> <span>System Architect</span> <span>Agentforce</span> <span>Java</span>
  </div>
</div>

<hr class="section-divider">

### 🏆 Professional Credentials

<div class="cert-mini-grid">
  {% for cert in site.data.mycerts %}
  <div class="cert-mini-card">
    <img src="{{ cert.image | relative_url }}" class="cert-mini-icon">
    <div class="cert-mini-info">
      <p class="cert-mini-title">{{ cert.title }}</p>
      <p class="cert-mini-date">{{ cert.date }}</p>
    </div>
  </div>
  {% endfor %}
</div>

<hr class="section-divider">

### ✍️ Recent Archive
