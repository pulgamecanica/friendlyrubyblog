# 🚀 Friendly Ruby Blog

![Repo Visualization](app/assets/images/circle.svg)

> A modern, interactive blogging platform built with Ruby on Rails 8, featuring live code execution, real-time collaboration, and a beautiful content management system.

## ✨ Key Features

### 📝 **Rich Content Creation**
- **Multi-format Blocks**: Create documents with Markdown, HTML, Rich Text(pending), Code, and Image blocks
- **Interactive Code Execution**: Run Ruby, Python, JavaScript, C/C++, and Bash code directly in the browser
- **Live Markdown Preview**: Real-time preview with syntax highlighting
- **Drag & Drop Sorting**: Reorder content blocks with intuitive drag-and-drop interface
- **Image Management**: Upload and manage images with automatic processing

### 🔧 **Advanced Author Tools**
- **Document Management**: Create posts, notes, and pages with rich metadata
- **Series Organization**: Group related content into logical series
- **Tag System**: Dynamic tag creation and management with comma-separated input
- **Publishing Control**: Draft/publish workflow with scheduling capabilities
- **Version History**: Track all changes with Paper Trail integration

### 🎨 **Modern User Experience**
- **Responsive Design**: Beautiful Tailwind CSS interface that works on all devices
- **Real-time Notifications**: Custom toast notification system with Stimulus
- **Progressive Enhancement**: Works with or without JavaScript
- **Smooth Interactions**: Turbo-powered SPA-like experience
- **Accessibility**: Built with semantic HTML and ARIA standards

### 🛡️ **Security & Performance**
- **Input Sanitization**: Secure HTML processing with Sanitize gem
- **Code Execution Sandboxing**: Safe code execution environment with timeouts
- **Authentication**: Robust user authentication with Devise
- **Search Integration**: Full-text search with pg_search
- **Caching**: Optimized performance with Rails caching

## 🏗️ Architecture

### **Core Models**
- **Document**: Main content entity (posts, notes, pages)
- **Block**: Polymorphic content blocks (Markdown, Code, Image, HTML, RichText)
- **Series**: Content organization and sequencing
- **Author**: User management and authentication
- **Comment**: Community engagement system
- **Language**: Code execution language support

### **Interactive Features**
- **Code Execution Service**: Secure, sandboxed code execution
- **WebSocket Integration**: Real-time updates with ActionCable
- **Background Jobs**: Asynchronous processing with SolidQueue

### **Frontend Technologies**
- **Stimulus Controllers**: 13 interactive components
- **Turbo Streams**: Real-time UI updates
- **Import Maps**: Modern JavaScript without bundling
- **Tailwind CSS**: Utility-first styling
- **Prism.js**: Syntax highlighting

## 🚀 Getting Started

### **Prerequisites**
- Ruby 3.3.6+
- PostgreSQL 13+
- Node.js 18+ (for Tailwind CSS)

### **Installation**

```bash
# Clone the repository
git clone https://github.com/your-username/friendlyrubyblog.git
cd friendlyrubyblog

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Install JavaScript dependencies
npm install

# Start the application
bin/dev
```

The application will be available at `http://localhost:3000`

### **Environment Setup**

```bash
# Create environment file
cp .env.example .env

# Configure your database
DATABASE_URL=postgresql://username:password@localhost/friendlyrubyblog_development

# Set your secret key
SECRET_KEY_BASE=$(rails secret)
```

## 🧪 Testing

The project includes comprehensive test coverage with RSpec:

```bash
# Run the full test suite
bundle exec rspec

# Run specific tests
bundle exec rspec spec/models/
bundle exec rspec spec/features/

# Generate coverage report
bundle exec rspec --format documentation
```

**Test Coverage**: 17 test files covering models, controllers, and system interactions

## 🏃‍♂️ Development

### **Available Commands**

```bash
# Development server with live reloading
bin/dev

# Rails console
rails console

# Database operations
rails db:migrate
rails db:rollback
rails db:reset

# Code quality
bundle exec rubocop
bundle exec brakeman

# Asset compilation
rails assets:precompile
```

### **Key Development Features**

- **Live Reloading**: Automatic browser refresh during development
- **Debug Tools**: Comprehensive debugging with the debug gem
- **Code Quality**: Automated linting with RuboCop Rails Omakase
- **Security Scanning**: Vulnerability detection with Brakeman
- **Test Coverage**: SimpleCov integration for coverage reporting

## 🚀 Deployment

### **Production Deployment**

The application is ready for deployment with:

- **Kamal**: Modern deployment toolkit for Docker containers
- **Thruster**: HTTP/2 proxy for Puma
- **Solid Stack**: Database-backed caching, job processing, and WebSockets
- **Docker**: Containerized deployment with multi-stage builds

```bash
# Deploy with Kamal
kamal deploy

# Check deployment status
kamal app logs
```

### **Infrastructure Stack**

- **Web Server**: Puma with Thruster proxy
- **Database**: PostgreSQL with connection pooling
- **Caching**: Solid Cache (database-backed)
- **Job Processing**: Solid Queue
- **WebSockets**: Solid Cable
- **File Storage**: Active Storage with cloud provider support

## 🔧 Configuration

### **Code Execution Languages**

Currently supported languages for interactive execution:

- Ruby 3.3+
- Python 3.x
- JavaScript (Node.js)
- C (GCC)
- C++ (G++)
- Bash/Shell scripts

### **Content Types**

- **Posts**: Blog articles with full publishing workflow
- **Notes**: Quick thoughts and shorter content
- **Pages**: Static content pages

### **Block Types**

- **MarkdownBlock**: Rich markdown content with live preview
- **CodeBlock**: Syntax-highlighted code with execution capabilities
- **ImageBlock**: Image galleries with drag-and-drop upload
- **HtmlBlock**: Raw HTML for advanced formatting
- **RichTextBlock**: WYSIWYG rich text editing

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### **Development Workflow**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Implement your feature
5. Run the test suite
6. Submit a pull request

### **Code Standards**

- Follow RuboCop Rails Omakase style guide
- Write comprehensive tests
- Include documentation for new features
- Maintain security best practices

## 📚 API Documentation

### **Public API Endpoints**

- `GET /` - Document index
- `GET /documents/:id` - Document show
- `GET /series` - Series index
- `GET /series/:id` - Series show with documents
- `GET /tags/:id` - Tag-filtered documents

### **Author API Endpoints**

- `POST /author/documents` - Create document
- `PATCH /author/documents/:id` - Update document
- `PATCH /author/documents/:id/publish` - Publish document
- `POST /author/documents/:id/blocks` - Create content block
- `PATCH /author/documents/:id/blocks/:id/toggle_interactive` - Toggle code execution

## 🔒 Security

- **Input Validation**: Comprehensive input sanitization
- **SQL Injection Protection**: Parameterized queries throughout
- **XSS Prevention**: HTML sanitization with allowlisted tags
- **CSRF Protection**: Built-in Rails CSRF tokens
- **Code Execution Sandboxing**: Secure isolated execution environment
- **Authentication**: Secure session management with Devise

## 📊 Monitoring

### **Health Checks**

- `GET /up` - Application health status
- Database connectivity verification
- Essential service status monitoring

### **Logging**

- Structured JSON logging in production
- Request/response tracking
- Performance monitoring
- Error tracking and alerting

## 🙏 Acknowledgments

- Built with [Ruby on Rails 8](https://rubyonrails.org/)
- Styled with [Tailwind CSS](https://tailwindcss.com/)
- Interactive features powered by [Hotwire](https://hotwired.dev/)
- Code highlighting by [Prism.js](https://prismjs.com/)

---

**Made with ❤️ by pulgamecanica**
