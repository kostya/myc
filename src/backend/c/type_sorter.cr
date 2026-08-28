struct Myc::Backend::C::TypeSorter
  getter order : Array(Type)
  getter all_types : Set(Type)

  def initialize
    @order = [] of Type
    @visited = Set(Type).new
    @visiting = Set(Type).new
    @all_types = Set(Type).new
  end

  def add(type : Type)
    return if primitive?(type)
    return if @all_types.includes?(type)

    collect_types(type)
  end

  def sort!
    @all_types.each { |t| visit(t) }
    self
  end

  private def collect_types(type : Type)
    return if primitive?(type)
    return if @all_types.includes?(type)

    @all_types << type

    strong_deps = get_strong_dependencies(type)
    strong_deps.each { |dep| collect_types(dep) }

    weak_deps = get_weak_dependencies(type)
    weak_deps.each { |dep| collect_types(dep) }
  end

  private def visit(type : Type)
    return if @visited.includes?(type)
    return if @visiting.includes?(type)

    @visiting << type

    strong_deps = get_strong_dependencies(type)
    strong_deps.each do |dep|
      next if primitive?(dep)

      if !@visiting.includes?(dep)
        visit(dep)
      end
    end

    @visiting.delete(type)
    @visited << type
    @order << type
  end

  private def get_strong_dependencies(type : Type) : Array(Type)
    deps = [] of Type

    case type
    when Myc::Type::FlatType
      if tt = type.target_type
        deps << tt
      end
    when Myc::Type::EnumType
      if i = type.index_type
        deps << i
      end
      type.data.each_value { |variant| deps << variant }
      if pt = type.payload_type
        deps << pt
      end
    when Myc::Type::EnumVariantType
      if cvt = type.composite_value_type
        deps << cvt
      end
    when Myc::Type::StructType
      type.data.each do |field_type|
        if field_type.is_a?(Type::PtrType)
        else
          deps << field_type
        end
      end
    end

    deps
  end

  private def get_weak_dependencies(type : Type) : Array(Type)
    deps = [] of Type

    case type
    when Type::PtrType
      deps << type.target_type
    when Myc::Type::StructType
      type.data.each do |field_type|
        if field_type.is_a?(Type::PtrType)
          deps << field_type.target_type
        end
      end
    when Myc::Type::Fn
      type.args.each { |arg| deps << arg }
      deps << type.ret
    end

    deps
  end

  private def primitive?(type : Type) : Bool
    case type
    when Type::IntType,
         Type::FloatType,
         Type::BoolType,
         Type::VoidType
      true
    else
      false
    end
  end
end
